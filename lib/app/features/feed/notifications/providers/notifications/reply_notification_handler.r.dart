// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/repository/comments_repository.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reply_notification_handler.r.g.dart';

class ReplyNotificationHandler extends GlobalSubscriptionEventHandler {
  ReplyNotificationHandler(this.commentsRepository, this.currentPubkey);

  final CommentsRepository commentsRepository;
  final String currentPubkey;

  @override
  bool canHandle(EventMessage eventMessage) {
    if (![ModifiablePostEntity.kind, ArticleEntity.kind, PostEntity.kind]
        .contains(eventMessage.kind)) {
      return false;
    }
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

    final isReplyToUser = [
      RelatedReplaceableEvent.tagName,
      RelatedImmutableEvent.tagName,
    ].any((tagName) {
      final entries = tags[tagName];
      return entries?.any(
            (tag) => tag.contains('reply') && tag.last == currentPubkey,
          ) ??
          false;
    });

    if (!isReplyToUser) {
      return false;
    }
    return true;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final entity = ModifiablePostEntity.fromEventMessage(eventMessage);

    final isOwnReply = entity.masterPubkey == currentPubkey;
    if (!isOwnReply) {
      await commentsRepository.save(entity);
    }
  }
}

@riverpod
ReplyNotificationHandler? replyNotificationHandler(Ref ref) {
  final commentsRepository = ref.watch(commentsRepositoryProvider);
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    return null;
  }

  return ReplyNotificationHandler(commentsRepository, currentPubkey);
}
