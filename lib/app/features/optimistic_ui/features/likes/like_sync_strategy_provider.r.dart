// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/user_sent_likes_dao.m.dart';
import 'package:ion/app/features/feed/providers/counters/like_reaction_provider.r.dart';
import 'package:ion/app/features/feed/providers/delete_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/like_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/model/post_like.f.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'like_sync_strategy_provider.r.g.dart';

@riverpod
SyncStrategy<PostLike> likeSyncStrategy(Ref ref) {
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);
  final userSentLikesDao = ref.read(userSentLikesDaoProvider);

  return LikeSyncStrategy(
    sendReaction: (reaction) async {
      final hasLiked = await userSentLikesDao.hasUserLiked(reaction.eventReference);
      if (hasLiked) {
        return;
      }
      final reactionEvent = await ionNotifier.sign(reaction);
      final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);
      await Future.wait([
        ionNotifier.sendEvent(reactionEvent),
        ionNotifier.sendEvent(
          reactionEvent,
          actionSource: ActionSourceUser(reaction.eventReference.masterPubkey),
          metadataBuilders: [userEventsMetadataBuilder],
          cache: false,
        ),
      ]);
    },
    getLikeEntity: (eventReference) => ref.read(likeReactionProvider(eventReference)),
    deleteReaction: (reactionEntity) async {
      await ref.read(deleteEntityControllerProvider.notifier).deleteEntity(reactionEntity);
    },
    updateCache: (eventReference, delta) {
      final likesCacheKey = EventCountResultEntity.cacheKeyBuilder(
        key: eventReference.toString(),
        type: EventCountResultType.reactions,
      );

      final existingEntity = ref.read(
        ionConnectCacheProvider.select(
          cacheSelector<EventCountResultEntity>(likesCacheKey),
        ),
      );

      if (existingEntity != null) {
        final reactionsMap =
            Map<String, dynamic>.from(existingEntity.data.content as Map<String, dynamic>);
        final currentCount = (reactionsMap[ReactionEntity.likeSymbol] ?? 0) as int;
        final newCount = (currentCount + delta).clamp(0, double.infinity).toInt();
        if (newCount == 0) {
          reactionsMap.remove(ReactionEntity.likeSymbol);
        } else {
          reactionsMap[ReactionEntity.likeSymbol] = newCount;
        }

        if (reactionsMap.isEmpty) {
          ref.read(ionConnectCacheProvider.notifier).remove(likesCacheKey);
        } else {
          final updatedEntity = existingEntity.copyWith(
            data: existingEntity.data.copyWith(
              content: reactionsMap,
            ),
          );
          ref.read(ionConnectCacheProvider.notifier).cache(updatedEntity);
        }
      }
    },
  );
}
