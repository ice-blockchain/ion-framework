// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/repository/likes_repository.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'like_notification_handler.r.g.dart';

class LikeNotificationHandler extends GlobalSubscriptionEventHandler {
  LikeNotificationHandler(this.likesRepository, this.currentPubkey);

  final LikesRepository likesRepository;
  final String currentPubkey;

  @override
  bool canHandle(EventMessage eventMessage) {
    return eventMessage.kind == ReactionEntity.kind;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final entity = ReactionEntity.fromEventMessage(eventMessage);
    final isOwnReaction = entity.masterPubkey == currentPubkey;
    if (!isOwnReaction) {
      await likesRepository.save(entity);
    }
  }
}

@riverpod
LikeNotificationHandler? likeNotificationHandler(Ref ref) {
  final likesRepository = ref.watch(likesRepositoryProvider);
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    return null;
  }

  return LikeNotificationHandler(likesRepository, currentPubkey);
}
