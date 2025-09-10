// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/pubkey_tag.f.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/repository/mentions_repository.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/features/ion_connect/model/source_post_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mention_notification_handler.r.g.dart';

class MentionNotificationHandler extends GlobalSubscriptionEventHandler {
  MentionNotificationHandler(this.mentionsRepository, this.currentPubkey);

  final MentionsRepository mentionsRepository;
  final String currentPubkey;

  @override
  bool canHandle(EventMessage eventMessage) {
    final isQuoteOfUser = eventMessage.tags
        .any((tag) => tag.first == QuotedReplaceableEvent.tagName && tag.last == currentPubkey);
    // quotes are handled in QuoteNotificationHandler
    if (isQuoteOfUser) {
      return false;
    }
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final hasUserInRelatedPubkey =
        tags[PubkeyTag.tagName]?.any((item) => item.last == currentPubkey) ?? false;

    if (!hasUserInRelatedPubkey) {
      return false;
    }
    final userMetadataRef =
        ReplaceableEventReference(masterPubkey: currentPubkey, kind: UserMetadataEntity.kind);
    final userMentionString = userMetadataRef.encode();
    final mentionAttribute = jsonEncode(MentionAttribute(userMentionString).toJson());
    final hasUserMention =
        tags[RichText.tagName]?.any((item) => item.toString().contains(mentionAttribute)) ?? false;

    if (!hasUserMention) {
      return false;
    }

    final isReplyToUser =
        tags[SourcePostReference.tagName]?.any((tag) => tag.contains('reply')) ?? false;

    if (isReplyToUser) {
      return false;
    }
    return true;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    switch (eventMessage.kind) {
      case ModifiablePostEntity.kind:
        final entity = ModifiablePostEntity.fromEventMessage(eventMessage);
        final isOwnMention = entity.masterPubkey == currentPubkey;
        if (!isOwnMention) {
          await mentionsRepository.save(entity);
        }
      case ArticleEntity.kind:
        final entity = ArticleEntity.fromEventMessage(eventMessage);
        final isOwnMention = entity.masterPubkey == currentPubkey;
        if (!isOwnMention) {
          await mentionsRepository.save(entity);
        }
      default:
        // No action needed for unsupported entity types
        break;
    }
  }
}

@riverpod
MentionNotificationHandler? mentionNotificationHandler(Ref ref) {
  final mentionsRepository = ref.watch(mentionsRepositoryProvider);
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    return null;
  }

  return MentionNotificationHandler(mentionsRepository, currentPubkey);
}
