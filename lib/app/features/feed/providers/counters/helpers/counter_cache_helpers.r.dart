// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/intents/add_quote_intent.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/intents/remove_quote_intent.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/post_repost_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_cache_helpers.r.g.dart';

/// Gets count from cache for a specific event and type
@riverpod
int countFromCache(
  Ref ref,
  EventReference eventReference,
  EventCountResultType type,
) {
  final cacheKey = EventCountResultEntity.cacheKeyBuilder(
    key: eventReference.toString(),
    type: type,
  );

  final entity = ref.watch(
    ionConnectCacheProvider.select(
      cacheSelector<EventCountResultEntity>(cacheKey),
    ),
  );

  final count = entity != null ? entity.data.content as int : 0;
  return count;
}

/// Gets both reposts and quotes counts from cache
@riverpod
({int repostsCount, int quotesCount}) repostCountsFromCache(
  Ref ref,
  EventReference eventReference,
) {
  return (
    repostsCount: ref.watch(
      countFromCacheProvider(eventReference, EventCountResultType.reposts),
    ),
    quotesCount: ref.watch(
      countFromCacheProvider(eventReference, EventCountResultType.quotes),
    ),
  );
}

/// Service for updating quote counters using optimistic UI
class QuoteCounterUpdater {
  QuoteCounterUpdater({
    required this.dispatchPostRepostService,
    required this.removeCacheItem,
    required this.getCurrentPostRepost,
    required this.findRepostInCache,
    required this.getRepostCounts,
    required this.cacheKeys,
  });

  final FutureOr<void> Function(OptimisticIntent<PostRepost> intent, PostRepost current)
      dispatchPostRepostService;
  final void Function(String cacheKey) removeCacheItem;
  final PostRepost? Function(String id) getCurrentPostRepost;
  final PostRepost? Function(EventReference) findRepostInCache;
  final ({int repostsCount, int quotesCount}) Function(EventReference) getRepostCounts;
  final List<String> cacheKeys;

  Future<void> updateQuoteCounter(
    EventReference quotedEvent, {
    required bool isAdding,
  }) async {
    final id = quotedEvent.toString();

    var current = getCurrentPostRepost(id);
    if (current == null) {
      final cached = findRepostInCache(quotedEvent);
      if (cached != null) {
        current = cached;
      } else {
        final counts = getRepostCounts(quotedEvent);
        current = PostRepost(
          eventReference: quotedEvent,
          repostsCount: counts.repostsCount,
          quotesCount: counts.quotesCount,
          repostedByMe: false,
        );
      }
    }

    final intent = isAdding ? const AddQuoteIntent() : const RemoveQuoteIntent();
    await dispatchPostRepostService(intent, current);

    _invalidateRepostCounterCache(quotedEvent);
  }

  /// Invalidates repost and quote counters cache for a specific event
  void _invalidateRepostCounterCache(EventReference eventReference) {
    final repostsCacheKey = EventCountResultEntity.cacheKeyBuilder(
      key: eventReference.toString(),
      type: EventCountResultType.reposts,
    );
    final quotesCacheKey = EventCountResultEntity.cacheKeyBuilder(
      key: eventReference.toString(),
      type: EventCountResultType.quotes,
    );

    removeCacheItem(repostsCacheKey);
    removeCacheItem(quotesCacheKey);
  }

  void invalidateAllReactionCaches() {
    final reactionTypeString = EventCountResultType.reactions.toShortString();
    final reactionKeys = cacheKeys.where((key) => key.endsWith(':$reactionTypeString')).toList();

    for (final key in reactionKeys) {
      removeCacheItem(key);
    }
  }
}

@riverpod
QuoteCounterUpdater quoteCounterUpdater(Ref ref) {
  return QuoteCounterUpdater(
    removeCacheItem: ref.watch(ionConnectCacheProvider.notifier).remove,
    getCurrentPostRepost: (id) => ref.watch(postRepostWatchProvider(id)).valueOrNull,
    findRepostInCache: (eventRef) => ref.watch(findRepostInCacheProvider(eventRef)),
    getRepostCounts: (eventRef) => ref.watch(repostCountsFromCacheProvider(eventRef)),
    cacheKeys: ref.watch(ionConnectCacheProvider).keys.toList(),
    dispatchPostRepostService: (intent, current) =>
        ref.read(postRepostServiceProvider).dispatch(intent, current),
  );
}
