// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/post_like_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'likes_count_provider.r.g.dart';

@riverpod
int likesCount(Ref ref, EventReference eventReference) {
  final optimistic =
      ref.watch(postLikeWatchProvider(eventReference.toString())).valueOrNull?.likesCount;

  if (optimistic != null) return optimistic;

  final cache = ref.watch(ionConnectCacheProvider);
  final uniqueLikes = cache.values
      .map((e) => e.entity)
      .whereType<ReactionEntity>()
      .where(
          (reaction) =>
              reaction.data.eventReference == eventReference &&
              reaction.data.content == ReactionEntity.likeSymbol,
        )
      .map((reaction) => reaction.masterPubkey)
      .toSet()
      .length;

  if (uniqueLikes > 0) {
    return uniqueLikes;
  }

  final counterEntity = ref.watch(
    ionConnectCacheProvider.select(
      cacheSelector<EventCountResultEntity>(
        EventCountResultEntity.cacheKeyBuilder(
          key: eventReference.toString(),
          type: EventCountResultType.reactions,
        ),
      ),
    ),
  );

  if (counterEntity == null) return 0;

  final reactionsCount = counterEntity.data.content as Map<String, dynamic>;

  return (reactionsCount[ReactionEntity.likeSymbol] ?? 0) as int;
}
