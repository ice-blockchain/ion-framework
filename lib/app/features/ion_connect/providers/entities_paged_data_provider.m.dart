// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entities_paged_data_provider.m.freezed.dart';

part 'entities_paged_data_provider.m.g.dart';

abstract class PagedNotifier {
  Future<void> fetchEntities();

  void refresh();

  void insertEntity(IonConnectEntity entity);

  void deleteEntity(IonConnectEntity entity);
}

abstract class PagedState {
  Set<IonConnectEntity>? get items;

  bool get hasMore;
}

mixin DelegatedPagedNotifier implements PagedNotifier {
  @override
  Future<void> fetchEntities() async {
    return getDelegate().fetchEntities();
  }

  @override
  void refresh() {
    return getDelegate().refresh();
  }

  @override
  void insertEntity(IonConnectEntity entity) {
    getDelegate().insertEntity(entity);
  }

  @override
  void deleteEntity(IonConnectEntity entity) {
    getDelegate().deleteEntity(entity);
  }

  PagedNotifier getDelegate();
}

@freezed
class EntitiesDataSource with _$EntitiesDataSource {
  const factory EntitiesDataSource({
    required ActionSource actionSource,
    required List<RequestFilter> requestFilters,
    required bool Function(IonConnectEntity entity) entityFilter,
    bool Function(IonConnectEntity entity)? pagedFilter,
  }) = _EntitiesDataSource;
}

@freezed
class EntitiesPagedDataState with _$EntitiesPagedDataState {
  factory EntitiesPagedDataState({
    // Processing pagination params per data source
    required Paged<IonConnectEntity, Map<ActionSource, PaginationParams>> data,
  }) = _EntitiesPagedDataState;

  EntitiesPagedDataState._();

  bool get hasMore => data.pagination.values.any((params) => params.hasMore);
}

final class DataSourceFetchResult {
  const DataSourceFetchResult({
    required this.entry,
    required this.missingEvents,
    required this.pendingInserts,
  });

  factory DataSourceFetchResult.empty(ActionSource actionSource) {
    return DataSourceFetchResult(
      entry: MapEntry(actionSource, PaginationParams(hasMore: false)),
      missingEvents: {},
      pendingInserts: {},
    );
  }

  final MapEntry<ActionSource, PaginationParams> entry;
  final Set<EventsMetadataEntity> missingEvents;
  final Map<EventReference, int> pendingInserts;
}

@riverpod
class EntitiesPagedData extends _$EntitiesPagedData implements PagedNotifier {
  @override
  EntitiesPagedDataState? build(List<EntitiesDataSource>? dataSources) {
    if (dataSources != null) {
      Future.microtask(fetchEntities);

      return EntitiesPagedDataState(
        data: Paged.data(
          null,
          pagination: {for (final source in dataSources) source.actionSource: PaginationParams()},
        ),
      );
    }
    return null;
  }

  @override
  Future<void> fetchEntities() async {
    final currentState = state;
    if (dataSources == null || currentState == null || currentState.data is PagedLoading) {
      return;
    }

    state = currentState.copyWith(
      data: Paged.loading(currentState.data.items, pagination: currentState.data.pagination),
    );

    final fetchResults = await Future.wait(
      dataSources!.map(_fetchEntitiesFromDataSource),
    );
    final paginationEntries = fetchResults.map((result) => result.entry).toList();
    final missingEvents = fetchResults.expand((result) => result.missingEvents).toSet();
    final pendingInserts = <EventReference, int>{
      for (final result in fetchResults) ...result.pendingInserts,
    };

    state = state?.copyWith(
      data: Paged.data(
        state!.data.items ?? {},
        pagination: Map.fromEntries(paginationEntries),
      ),
    );

    await _handleMissingEvents(missingEvents, pendingInserts);
  }

  @override
  void refresh() {
    ref.invalidateSelf();
  }

  @override
  void deleteEntity(IonConnectEntity entity) {
    final items = state?.data.items;
    if (items == null) return;

    final updatedItems = {...items};
    final removed = updatedItems.remove(entity);

    if (removed) {
      state = state!.copyWith(
        data: state!.data.copyWith(items: updatedItems),
      );
    }
  }

  @override
  void insertEntity(IonConnectEntity entity, {int index = 0}) {
    final items = state?.data.items?.toList() ?? []
      ..insert(index, entity);
    state = state!.copyWith(
      data: state!.data.copyWith(items: items.toSet()),
    );
  }

  Future<DataSourceFetchResult> _fetchEntitiesFromDataSource(
    EntitiesDataSource dataSource,
  ) async {
    try {
      final currentState = state;
      final paginationParams = state?.data.pagination[dataSource.actionSource];

      if (currentState == null || paginationParams == null || !paginationParams.hasMore) {
        return DataSourceFetchResult.empty(dataSource.actionSource);
      }

      final requestMessage = RequestMessage();
      for (final filter in dataSource.requestFilters) {
        requestMessage.addFilter(
          filter.copyWith(until: () => paginationParams.until?.microsecondsSinceEpoch),
        );
      }

      final entitiesStream = ref.read(ionConnectNotifierProvider.notifier).requestEntities(
            requestMessage,
            actionSource: dataSource.actionSource,
          );

      final visible = (state!.data.items ?? {}).toList();
      var cursor = visible.length;

      DateTime? lastEventTime;
      final pagedFilter = dataSource.pagedFilter ?? dataSource.entityFilter;

      // Placeholders fetched later
      final missingEvents = <EventsMetadataEntity>{};

      // Where each placeholder *would* be inserted in visible list
      final pendingInserts = <EventReference, int>{};

      await for (final entity in entitiesStream) {
        final alreadyHas = state?.data.items?.contains(entity) ?? false;

        // Update pagination params
        if (pagedFilter(entity) && !alreadyHas) {
          lastEventTime = entity.createdAt.toDateTime;
        }

        // Update pending inserts
        if (entity is EventsMetadataEntity) {
          final ref = entity.data.metadataEventReference;
          if (ref != null && !pendingInserts.containsKey(ref)) {
            pendingInserts[ref] = cursor;
          }
          missingEvents.add(entity);
        }

        // Update state
        if (dataSource.entityFilter(entity) && !alreadyHas) {
          visible.add(entity);
          cursor = visible.length;
          state = state?.copyWith(
            data: Paged.loading(
              visible.toSet(),
              pagination: state!.data.pagination,
            ),
          );
        }
      }

      return DataSourceFetchResult(
        entry: MapEntry(
          dataSource.actionSource,
          PaginationParams(hasMore: lastEventTime != null, lastEventTime: lastEventTime),
        ),
        missingEvents: missingEvents,
        pendingInserts: pendingInserts,
      );
    } catch (e, stackTrace) {
      Logger.error(e, stackTrace: stackTrace, message: 'Data source data fetching failed');
      return DataSourceFetchResult.empty(dataSource.actionSource);
    }
  }

  Future<void> _handleMissingEvents(
    Set<EventsMetadataEntity> missingEvents,
    Map<EventReference, int> pendingInserts,
  ) async {
    if (missingEvents.isEmpty) return;

    final refs = missingEvents.map((event) => event.data.metadataEventReference).nonNulls.toList();
    final fetched = await ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
          eventReferences: refs,
        );

    final fetchedByRef = <EventReference, IonConnectEntity>{};
    for (final entity in fetched) {
      final ref = entity.toEventReference();
      fetchedByRef[ref] = entity;
    }

    final list = (state?.data.items ?? {}).toList();
    final inserts = <MapEntry<int, IonConnectEntity>>[];
    pendingInserts.forEach((ref, index) {
      final entity = fetchedByRef[ref];
      if (entity != null) inserts.add(MapEntry(index, entity));
    });
    inserts.sort((a, b) => a.key.compareTo(b.key));

    var shift = 0;
    for (final entry in inserts) {
      final i = entry.key + shift;
      if (i <= list.length) {
        list.insert(i, entry.value);
        shift++;
      } else {
        list.add(entry.value);
      }
    }

    final filtered = list.where((entity) {
      return dataSources!.any((dataSource) => dataSource.entityFilter(entity));
    });

    state = state!.copyWith(
      data: Paged.data(
        filtered.toSet(),
        pagination: state!.data.pagination,
      ),
    );
  }
}
