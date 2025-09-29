// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/providers/counters/helpers/counter_cache_helpers.r.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/intents/toggle_repost_intent.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/repost_sync_strategy_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_repost_provider.r.g.dart';

@riverpod
PostRepost? findRepostInCache(Ref ref, EventReference eventReference) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentPubkey == null) {
    return null;
  }

  final manager = ref.watch(postRepostManagerProvider);
  final optimisticState =
      manager.snapshot.where((pr) => pr.eventReference == eventReference).firstOrNull;

  if (optimisticState != null) {
    return optimisticState;
  }

  final myRepost = ref
      .watch(ionConnectCacheProvider)
      .values
      .map((e) => e.entity)
      .where((entity) => entity.masterPubkey == currentPubkey)
      .where((entity) => entity is RepostEntity || entity is GenericRepostEntity)
      .where((entity) {
    final repostedEventRef = entity is RepostEntity
        ? entity.data.eventReference
        : (entity as GenericRepostEntity).data.eventReference;
    return repostedEventRef == eventReference;
  }).firstOrNull;

  if (myRepost == null) {
    return null;
  }

  final counts = ref.watch(repostCountsFromCacheProvider(eventReference));

  final result = PostRepost(
    eventReference: eventReference,
    repostsCount: counts.repostsCount,
    quotesCount: counts.quotesCount,
    repostedByMe: true,
    myRepostReference: myRepost.toEventReference(),
  );

  return result;
}

@riverpod
List<PostRepost> loadRepostsFromCache(Ref ref) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) return [];

  final manager = ref.watch(postRepostManagerProvider);
  final optimisticStates = Map.fromEntries(
    manager.snapshot.map((pr) => MapEntry(pr.eventReference, pr)),
  );

  final repostEntities = ref.watch(
    ionConnectCacheProvider.select(
      (result) {
        final allEntities = result.values.map((e) => e.entity).toList();
        final reposts = allEntities
            .where((entity) => entity.masterPubkey == currentPubkey)
            .where((entity) => entity is RepostEntity || entity is GenericRepostEntity)
            .toList();

        return RepostEntities(items: reposts);
      },
    ),
  );

  final postReposts = <PostRepost>[];

  for (final entity in repostEntities.items) {
    final eventReference = entity is RepostEntity
        ? entity.data.eventReference
        : (entity as GenericRepostEntity).data.eventReference;

    final optimisticState = optimisticStates[eventReference];
    if (optimisticState != null) {
      postReposts.add(optimisticState);
      continue;
    }

    final counts = ref.watch(repostCountsFromCacheProvider(eventReference));

    postReposts.add(
      PostRepost(
        eventReference: eventReference,
        repostsCount: counts.repostsCount,
        quotesCount: counts.quotesCount,
        repostedByMe: true,
        myRepostReference: entity.toEventReference(),
      ),
    );
  }

  return postReposts;
}

@riverpod
OptimisticService<PostRepost> postRepostService(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final manager = ref.watch(postRepostManagerProvider);
  // optimistic state items are added only though dispatch and removed by the service itself
  final service = OptimisticService<PostRepost>(manager: manager);

  return service;
}

@riverpod
Stream<PostRepost?> postRepostWatch(Ref ref, String id) {
  keepAliveWhenAuthenticated(ref);
  final service = ref.watch(postRepostServiceProvider);
  final manager = ref.watch(postRepostManagerProvider);

  var last = manager.snapshot.firstWhereOrNull((e) => e.optimisticId == id);

  return service.watch(id).map((postRepost) {
    if (postRepost != null) {
      last = postRepost;
      return postRepost;
    }
    return last;
  });
}

@riverpod
OptimisticOperationManager<PostRepost> postRepostManager(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final strategy = ref.watch(repostSyncStrategyProvider);
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<PostRepost>(
    syncCallback: strategy.send,
    onError: (_, error) async {
      if (error is RepostCreationFailedException ||
          error is EntityNotFoundException ||
          error is FormatException ||
          error is UnsupportedRepostException) {
        return false;
      }

      return true;
    },
    enableLocal: localEnabled,
    clearOnSuccessfulSync: true,
  );

  ref.onDispose(manager.dispose);

  return manager;
}

@riverpod
class ToggleRepostNotifier extends _$ToggleRepostNotifier {
  @override
  void build() {}

  Future<void> toggle(EventReference eventReference) async {
    final service = ref.read(postRepostServiceProvider);
    final id = eventReference.toString();

    var current = ref.read(postRepostWatchProvider(id)).valueOrNull;
    current ??= _findOrCreatePostRepost(eventReference);

    await service.dispatch(const ToggleRepostIntent(), current);
  }

  PostRepost _findOrCreatePostRepost(EventReference eventReference) {
    final manager = ref.read(postRepostManagerProvider);
    final currentState =
        manager.snapshot.where((pr) => pr.eventReference == eventReference).firstOrNull;

    if (currentState != null) {
      return currentState;
    }

    final cached = ref.read(findRepostInCacheProvider(eventReference));

    if (cached != null) return cached;

    final counts = ref.read(repostCountsFromCacheProvider(eventReference));

    return PostRepost(
      eventReference: eventReference,
      repostsCount: counts.repostsCount,
      quotesCount: counts.quotesCount,
      repostedByMe: false,
    );
  }
}
