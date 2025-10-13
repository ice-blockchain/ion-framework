// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_entity_provider.r.g.dart';

@riverpod
Future<IonConnectEntity?> ionConnectEntity(
  Ref ref, {
  required EventReference eventReference,
  bool cache = true,
  bool network = true,
  String? search,
  ActionType? actionType,
  Duration? expirationDuration,
  DatabaseCacheStrategy? cacheStrategy,
}) async {
  final currentUser = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentUser == null) {
    throw const CurrentUserNotFoundException();
  }

  // Try to get from in-memory cache, then database cache, if found in database cache
  // put it also in in-memory cache
  if (cache) {
    final inMemoryEntity = ref.watch(
      ionConnectCacheProvider.select(
        cacheSelector(
          CacheableEntity.cacheKeyBuilder(eventReference: eventReference),
          expirationDuration: expirationDuration,
        ),
      ),
    );

    if (inMemoryEntity != null) {
      return inMemoryEntity;
    }

    final cacheService = ref.read(ionConnectDatabaseCacheProvider.notifier);

    final databaseEntity = await cacheService.get(
      eventReference.toString(),
      expirationDuration: expirationDuration,
      cacheStrategy: cacheStrategy ?? DatabaseCacheStrategy.alwaysReturn,
    );

    if (databaseEntity != null) {
      return databaseEntity;
    }
  }

  if (network) {
    return ref.watch(
      ionConnectNetworkEntityProvider(
        search: search,
        actionType: actionType,
        eventReference: eventReference,
      ).future,
    );
  }
  return null;
}

@riverpod
IonConnectEntity? ionConnectInMemoryEntity(
  Ref ref, {
  required EventReference eventReference,
  Duration? expirationDuration,
}) =>
    ref.watch(
      ionConnectCacheProvider.select(
        cacheSelector(
          CacheableEntity.cacheKeyBuilder(eventReference: eventReference),
          expirationDuration: expirationDuration,
        ),
      ),
    );

// We have to keep this provider in order to not break existing sync entity provider
// logic
//TODO: remove in future refactor
@riverpod
Future<IonConnectEntity?> ionConnectDatabaseEntity(
  Ref ref, {
  required EventReference eventReference,
}) async {
  return ref.read(ionConnectDatabaseCacheProvider.notifier).get(eventReference.toString());
}

@riverpod
Future<IonConnectEntity?> ionConnectNetworkEntity(
  Ref ref, {
  required EventReference eventReference,
  String? search,
  ActionType? actionType,
  ActionSource? actionSource,
}) async {
  final aSource = actionSource ?? ActionSourceUser(eventReference.masterPubkey);

  if (eventReference is ImmutableEventReference) {
    final requestMessage = RequestMessage()
      ..addFilter(
        RequestFilter(
          ids: [eventReference.eventId],
          search: search,
          limit: 1,
        ),
      );

    return ref.read(ionConnectNotifierProvider.notifier).requestEntity(
          requestMessage,
          actionSource: aSource,
          actionType: actionType,
          entityEventReference: eventReference,
        );
  } else if (eventReference is ReplaceableEventReference) {
    final requestMessage = RequestMessage()
      ..addFilter(
        RequestFilter(
          kinds: [eventReference.kind],
          authors: [eventReference.masterPubkey],
          tags: {
            if (eventReference.dTag.isNotEmpty) '#d': [eventReference.dTag],
          },
          search: search,
          limit: 1,
        ),
      );
    return ref.read(ionConnectNotifierProvider.notifier).requestEntity(
          requestMessage,
          actionSource: aSource,
          actionType: actionType,
          entityEventReference: eventReference,
        );
  } else {
    throw UnsupportedEventReference(eventReference);
  }
}

@riverpod
class IonConnectNetworkEntitiesManager extends _$IonConnectNetworkEntitiesManager {
  @override
  FutureOr<void> build() {}

  Stream<IonConnectEntity> fetch({
    required ActionSource actionSource,
    required List<EventReference> eventReferences,
    String? search,
    ActionType? actionType,
  }) async* {
    if (eventReferences.isEmpty) {
      yield* const Stream.empty();
    }

    final aType = actionType ?? ActionType.read;

    final immutableRefs = eventReferences.whereType<ImmutableEventReference>().toList();
    final replaceableRefs = eventReferences.whereType<ReplaceableEventReference>().toList();

    final replaceableRefsFilters = _buildReplaceableRefsFilters(replaceableRefs, search);
    final immutableRefsFilters = _buildImmutableRefsFilters(immutableRefs, search);

    final requestMessage = RequestMessage()
      ..filters.addAll(
        [
          ...immutableRefsFilters,
          ...replaceableRefsFilters,
        ],
      );

    final entityStream = ref.read(ionConnectNotifierProvider.notifier).requestEntities(
          requestMessage,
          actionType: aType,
          actionSource: actionSource,
        );

    yield* entityStream;
  }

  // Helper method to build filters for replaceable event references
  List<RequestFilter> _buildImmutableRefsFilters(
    List<ImmutableEventReference> immutableRefs,
    String? search,
  ) {
    final filters = <RequestFilter>[];

    if (immutableRefs.isNotEmpty) {
      filters.add(
        RequestFilter(
          search: search,
          ids: immutableRefs.map((e) => e.eventId).toList(),
        ),
      );
    }

    return filters;
  }

  // Helper method to build filters for replaceable event references
  List<RequestFilter> _buildReplaceableRefsFilters(
    List<ReplaceableEventReference> replaceableRefs,
    String? search,
  ) {
    final filters = <RequestFilter>[];

    if (replaceableRefs.isNotEmpty) {
      // Group by kind and dTag
      final grouped = <String, Map<String, List<ReplaceableEventReference>>>{};

      for (final ref in replaceableRefs) {
        final kindKey = ref.kind.toString();
        final dTagKey = ref.dTag;
        final dTagMap =
            grouped.putIfAbsent(kindKey, () => <String, List<ReplaceableEventReference>>{});
        dTagMap.putIfAbsent(dTagKey, () => <ReplaceableEventReference>[]).add(ref);
      }

      for (final kindEntry in grouped.entries) {
        final kind = int.parse(kindEntry.key);
        for (final dTagEntry in kindEntry.value.entries) {
          final dTag = dTagEntry.key;
          final refs = dTagEntry.value;
          if (dTag.isEmpty) {
            // Combine all masterPubkeys for this kind with empty dTag
            filters.add(
              RequestFilter(
                kinds: [kind],
                authors: refs.map((e) => e.masterPubkey).toList(),
                search: search,
              ),
            );
          } else {
            // Create separate filter for each ref with non-empty dTag
            for (final ref in refs) {
              filters.add(
                RequestFilter(
                  kinds: [ref.kind],
                  authors: [ref.masterPubkey],
                  tags: {
                    '#d': [ref.dTag],
                  },
                  search: search,
                ),
              );
            }
          }
        }
      }
    }

    return filters;
  }
}

@riverpod
IonConnectEntity? ionConnectSyncEntity(
  Ref ref, {
  required EventReference eventReference,
  bool cache = true,
  bool database = false,
  bool network = true,
  String? search,
}) {
  final currentUser = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentUser == null) {
    throw const CurrentUserNotFoundException();
  }
  if (cache) {
    final inMemoryEntity =
        ref.watch(ionConnectInMemoryEntityProvider(eventReference: eventReference));
    if (inMemoryEntity != null) {
      return inMemoryEntity;
    }
  }

  if (database) {
    final databaseEntityState =
        ref.watch(ionConnectDatabaseEntityProvider(eventReference: eventReference));
    if (databaseEntityState.isLoading) {
      return null;
    }

    final databaseEntity = databaseEntityState.valueOrNull;
    if (databaseEntity != null) {
      return databaseEntity;
    }
  }

  if (network) {
    return ref
        .watch(ionConnectNetworkEntityProvider(eventReference: eventReference, search: search))
        .valueOrNull;
  }
  return null;
}

@riverpod
class IonConnectEntitiesManager extends _$IonConnectEntitiesManager {
  @override
  FutureOr<void> build() {}

  Future<List<IonConnectEntity>> fetch({
    required List<EventReference> eventReferences,
    String? search,
    bool cache = true,
    bool network = true,
    ActionType? actionType,
    ActionSource? actionSource,
    Duration? expirationDuration,
  }) async {
    final remainingEvents = eventReferences.toSet();
    final results = <IonConnectEntity>[];

    // In-memory cache first
    if (cache) {
      final inMemoryEntities = remainingEvents
          .map(
            (eventReference) => ref.read(
              ionConnectCacheProvider.select(
                cacheSelector(
                  CacheableEntity.cacheKeyBuilder(eventReference: eventReference),
                  expirationDuration: expirationDuration,
                ),
              ),
            ),
          )
          .whereType<IonConnectEntity>()
          .toList();
      results.addAll(inMemoryEntities);
      remainingEvents.removeAll(inMemoryEntities.map((e) => e.toEventReference()));

      // Database cache
      if (remainingEvents.isNotEmpty) {
        final cacheService = ref.read(ionConnectDatabaseCacheProvider.notifier);
        final databaseEntities = await cacheService.getAllFiltered(
          expirationDuration: expirationDuration,
          cacheKeys: remainingEvents.map((e) => e.toString()).toList(),
        );
        results.addAll(databaseEntities);
        remainingEvents.removeAll(databaseEntities.map((e) => e.toEventReference()));
      }
    }

    if (network && remainingEvents.isNotEmpty) {
      final notCachedEvents = remainingEvents.toList();

      final stream = ref
          .read(ionConnectNetworkEntitiesManagerProvider.notifier)
          .fetch(
            search: search,
            actionType: actionType,
            eventReferences: notCachedEvents,
            actionSource: actionSource ??
                ActionSource.optimalRelays(
                  strategy: OptimalRelaysStrategy.mostUsers,
                  masterPubkeys: notCachedEvents.map((e) => e.masterPubkey).toSet().toList(),
                ),
          )
          .handleError((Object e, StackTrace stack) {
        Logger.log(
          'Error fetching network entities for optimal relays',
          stackTrace: stack,
          error: e,
        );
      });

      results.addAll(await stream.toList());
    }

    return results;
  }
}
