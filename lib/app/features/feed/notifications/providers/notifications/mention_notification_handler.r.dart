// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/repository/mentions_repository.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mention_notification_handler.r.g.dart';

class MentionNotificationHandler extends GlobalSubscriptionEventHandler {
  MentionNotificationHandler(this.mentionsRepository, this.currentPubkey);

  final MentionsRepository mentionsRepository;
  final String currentPubkey;

  @override
  bool canHandle(EventMessage eventMessage) {
    final isQuote = eventMessage.tags.any((tag) => tag.first == 'Q' && tag.last == currentPubkey);
    // quotes are handled in QuoteNotificationHandler
    if (isQuote) {
      return false;
    }
    return switch (eventMessage.kind) {
      ModifiablePostEntity.kind => () {
          final entity = ModifiablePostEntity.fromEventMessage(eventMessage);

          final mentionAttribute = _userMentionAttribute();
          final entityHasCurrentUserMention =
              entity.data.richText?.content.contains(mentionAttribute) ?? false;

          final hasUserPubKeyMention =
              entity.data.relatedPubkeys?.map((element) => element.value).contains(currentPubkey) ??
                  false;
          // replies are handled in ReplyNotificationHandler
          final isReply = entity.data.relatedEvents?.any(
                (event) =>
                    event.marker == RelatedEventMarker.reply &&
                    event.eventReference is ReplaceableEventReference,
              ) ??
              false;

          return hasUserPubKeyMention && entityHasCurrentUserMention && !isReply;
        }(),
      ArticleEntity.kind => () {
          final mentionAttribute = _userMentionAttribute();
          final entity = ArticleEntity.fromEventMessage(eventMessage);
          final entityHasCurrentUserMention =
              entity.data.richText?.content.contains(mentionAttribute) ?? false;
          final hasUserPubKeyMention =
              entity.data.relatedPubkeys?.map((element) => element.value).contains(currentPubkey) ??
                  false;
          return hasUserPubKeyMention && entityHasCurrentUserMention;
        }(),
      _ => false,
    };
  }

  String _userMentionAttribute() {
    final userMetadataRef =
        ReplaceableEventReference(masterPubkey: currentPubkey, kind: UserMetadataEntity.kind);
    final userMentionString = userMetadataRef.encode();
    final mentionAttribute = jsonEncode(MentionAttribute(userMentionString).toJson());
    return mentionAttribute;
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
