// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
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

    final paginationEntries = await Future.wait(
      dataSources!.map(_fetchEntitiesFromDataSource),
    );

    state = state?.copyWith(
      data: Paged.data(
        state!.data.items ?? {},
        pagination: Map.fromEntries(paginationEntries),
      ),
    );
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

  Future<MapEntry<ActionSource, PaginationParams>> _fetchEntitiesFromDataSource(
    EntitiesDataSource dataSource,
  ) async {
    try {
      final currentState = state;
      final paginationParams = state?.data.pagination[dataSource.actionSource];

      if (currentState == null || paginationParams == null || !paginationParams.hasMore) {
        return MapEntry(dataSource.actionSource, PaginationParams(hasMore: false));
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

      DateTime? lastEventTime;
      final pagedFilter = dataSource.pagedFilter ?? dataSource.entityFilter;

      await for (final entity in entitiesStream) {
        final stateFilter = !(state?.data.items?.contains(entity)).falseOrValue;

        // Update pagination params
        if (pagedFilter(entity) && stateFilter) {
          lastEventTime = entity.createdAt.toDateTime;
        }

        // Update state
        if (dataSource.entityFilter(entity) && stateFilter) {
          state = state?.copyWith(
            data: Paged.loading(
              {...state!.data.items ?? {}}..add(entity),
              pagination: state!.data.pagination,
            ),
          );
        }
      }

      return MapEntry(
        dataSource.actionSource,
        PaginationParams(hasMore: lastEventTime != null, lastEventTime: lastEventTime),
      );
    } catch (e, stackTrace) {
      Logger.error(e, stackTrace: stackTrace, message: 'Data source data fetching failed');
      return MapEntry(
        dataSource.actionSource,
        PaginationParams(hasMore: false),
      );
    }
  }
}
