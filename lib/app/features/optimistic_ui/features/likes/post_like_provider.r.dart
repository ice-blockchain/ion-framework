// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests_interaction.dart';
import 'package:ion/app/features/feed/providers/counters/like_reaction_provider.r.dart';
import 'package:ion/app/features/feed/providers/counters/likes_count_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/optimistic_ui/database/dao/user_sent_likes_dao.m.dart';
import 'package:ion/app/features/optimistic_ui/database/tables/user_sent_likes_table.d.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/like_sync_strategy_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/model/post_like.f.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/toggle_like_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_like_provider.r.g.dart';

@riverpod
class PostLikeServiceNotifier extends _$PostLikeServiceNotifier {
  @override
  OptimisticService<PostLike> build() {
    keepAliveWhenAuthenticated(ref);
    final manager = ref.watch(postLikeManagerProvider);
    // no need to initialise the service with initial items,
    // optimistic state should be used for the pending operation only and cache should be use as source in other cases
    return OptimisticService<PostLike>(manager: manager);
  }
}

@riverpod
Stream<PostLike?> postLikeWatch(Ref ref, String id) {
  keepAliveWhenAuthenticated(ref);
  final service = ref.watch(postLikeServiceNotifierProvider);
  final manager = ref.watch(postLikeManagerProvider);

  var last = manager.snapshot.firstWhereOrNull((e) => e.optimisticId == id);

  return service.watch(id).map((postLike) {
    if (postLike != null) {
      last = postLike;
      return postLike;
    }
    return last;
  });
}

@riverpod
OptimisticOperationManager<PostLike> postLikeManager(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final strategy = ref.watch(likeSyncStrategyProvider);
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<PostLike>(
    syncCallback: strategy.send,
    onError: (_, __) async => true,
    enableLocal: localEnabled,
    clearOnSuccessfulSync: true,
  );

  ref.onDispose(manager.dispose);

  return manager;
}

@riverpod
class ToggleLikeNotifier extends _$ToggleLikeNotifier {
  @override
  void build() {
    keepAliveWhenAuthenticated(ref);
  }

  Future<void> toggle(EventReference eventReference) async {
    final userSentLikesDao = ref.read(userSentLikesDaoProvider);
    final service = ref.read(postLikeServiceNotifierProvider);
    final id = eventReference.toString();

    if (await userSentLikesDao.hasUserLiked(eventReference)) {
      return;
    }

    var current = ref.read(postLikeWatchProvider(id)).valueOrNull;

    current ??= PostLike(
      eventReference: eventReference,
      likesCount: ref.read(likesCountProvider(eventReference)),
      likedByMe: ref.read(isLikedProvider(eventReference)),
    );

    if (current.likedByMe) {
      await userSentLikesDao.deleteLike(eventReference);
    } else {
      final hasLiked = await userSentLikesDao.hasUserLiked(eventReference);
      if (hasLiked) {
        return;
      }

      await userSentLikesDao.insertOrUpdateLike(
        eventReference: eventReference,
        status: UserSentLikeStatus.pending,
      );
    }

    try {
      await service.dispatch(ToggleLikeIntent(), current);

      if (!current.likedByMe) {
        await _updateInterestsOnLike(eventReference);
      }

      if (!current.likedByMe) {
        await userSentLikesDao.updateLikeStatus(
          eventReference: eventReference,
          status: UserSentLikeStatus.confirmed,
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      await userSentLikesDao.deleteLike(eventReference);
      rethrow;
    }
  }

  Future<void> _updateInterestsOnLike(EventReference eventReference) async {
    final entity = await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);

    if (entity == null) throw EntityNotFoundException(eventReference);

    final hasParent = switch (entity) {
      ModifiablePostEntity() => entity.data.parentEvent != null,
      PostEntity() => entity.data.parentEvent != null,
      ArticleEntity() => false,
      _ => throw UnsupportedEntityType(entity)
    };

    final tags = switch (entity) {
      ModifiablePostEntity() => entity.data.relatedHashtags,
      PostEntity() => entity.data.relatedHashtags,
      ArticleEntity() => entity.data.relatedHashtags,
      _ => throw UnsupportedEntityType(entity)
    };

    final interaction =
        hasParent ? FeedInterestInteraction.likeReply : FeedInterestInteraction.likePostOrArticle;
    final interactionCategories = tags?.map((tag) => tag.value).toList() ?? [];

    if (interactionCategories.isNotEmpty) {
      await ref
          .read(feedUserInterestsNotifierProvider.notifier)
          .updateInterests(interaction, interactionCategories);
    }
  }
}
