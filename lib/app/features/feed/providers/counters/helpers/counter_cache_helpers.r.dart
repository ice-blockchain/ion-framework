// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/intents/add_quote_intent.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/intents/remove_quote_intent.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/post_repost_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
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

@riverpod
void invalidateAllReactionCaches(Ref ref) {
  final cache = ref.read(ionConnectCacheProvider);
  final reactionKeys = cache.keys.where((key) => 
    key.contains('EventCountResult') && key.contains('reactions'),
  ).toList();
  
  final cacheNotifier = ref.read(ionConnectCacheProvider.notifier);
  for (final key in reactionKeys) {
    cacheNotifier.remove(key);
  }
}

/// Service for updating quote counters using optimistic UI
class QuoteCounterUpdater {
  QuoteCounterUpdater({
    required this.postRepostService,
    required this.removeCacheItem,
    required this.getCurrentPostRepost,
    required this.findRepostInCache,
    required this.getRepostCounts,
  });

  final OptimisticService<PostRepost> postRepostService;
  final void Function(String cacheKey) removeCacheItem;
  final PostRepost? Function(String id) getCurrentPostRepost;
  final PostRepost? Function(EventReference) findRepostInCache;
  final ({int repostsCount, int quotesCount}) Function(EventReference) getRepostCounts;

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
    await postRepostService.dispatch(intent, current);

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
}

@riverpod
QuoteCounterUpdater quoteCounterUpdater(Ref ref) {
  return QuoteCounterUpdater(
    postRepostService: ref.watch(postRepostServiceProvider),
    removeCacheItem: ref.watch(ionConnectCacheProvider.notifier).remove,
    getCurrentPostRepost: (id) => ref.watch(postRepostWatchProvider(id)).valueOrNull,
    findRepostInCache: (eventRef) => ref.watch(findRepostInCacheProvider(eventRef)),
    getRepostCounts: (eventRef) => ref.watch(repostCountsFromCacheProvider(eventRef)),
  );
}
