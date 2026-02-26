// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_loading.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/username_text_span.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_tap_gesture_recognizer.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/l10n/i10n.dart';

class CommentNotificationInfo extends HookConsumerWidget {
  const CommentNotificationInfo({
    required this.notification,
    super.key,
  });

  final CommentIonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubkey = notification.eventReference.masterPubkey;
    final userData = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    final recognizer = useTapGestureRecognizer(
      onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
    );
    final eventTypeLabel = _getEventTypeLabel(ref);
    final relatedEntity = _getRelatedEntity(ref);

    if (userData == null) {
      return const NotificationInfoLoading();
    }

    final isAuthor = _isAuthor(ref, relatedEntity);

    final description = switch (notification.type) {
      CommentIonNotificationType.reply => isAuthor
          ? context.i18n.notifications_reply(eventTypeLabel)
          : context.i18n.notifications_reply_other_user(eventTypeLabel),
      CommentIonNotificationType.quote => isAuthor
          ? context.i18n.notifications_share(eventTypeLabel)
          : context.i18n.notifications_share_other_user(eventTypeLabel),
      CommentIonNotificationType.repost => context.i18n.notifications_repost(eventTypeLabel),
    };

    final textSpan = replaceString(
      description,
      tagRegex('username'),
      (match, index) => buildUsernameTextSpan(
        context,
        userData: userData.data,
        recognizer: recognizer,
      ),
    );

    return NotificationInfoText(
      textSpan: textSpan,
      timestamp: notification.timestamp,
      showTodayLabel: false,
    );
  }

  String _getEventTypeLabel(WidgetRef ref) {
    final relatedEntity = _getRelatedEntity(ref);
    return switch (relatedEntity) {
      ModifiablePostEntity() when relatedEntity.isStory => ref.context.i18n.common_story,
      ModifiablePostEntity(:final data) when data.parentEvent != null =>
        ref.context.i18n.notifications_comment,
      ModifiablePostEntity() => ref.context.i18n.notifications_post,
      ArticleEntity() => ref.context.i18n.common_article,
      GenericRepostEntity() => ref.context.i18n.notifications_post,
      _ => '',
    };
  }

  IonConnectEntity? _getRelatedEntity(WidgetRef ref) {
    final entity = ref.watch(
      ionConnectSyncEntityWithCountersProvider(
        eventReference: notification.eventReference,
      ),
    );
    if (entity == null) return null;

    final relatedEventReference = switch (entity) {
      GenericRepostEntity() => entity.data.eventReference,
      ModifiablePostEntity() =>
        entity.data.parentEvent?.eventReference ?? entity.data.quotedEvent?.eventReference,
      _ => null,
    };

    if (relatedEventReference != null) {
      return ref.watch(
        ionConnectSyncEntityWithCountersProvider(
          eventReference: relatedEventReference,
        ),
      );
    }

    return null;
  }

  bool _isAuthor(WidgetRef ref, IonConnectEntity? relatedEntity) {
    if (notification.type == CommentIonNotificationType.quote &&
        relatedEntity is CommunityTokenDefinitionEntity) {
      return _isOwnToken(ref, tokenDefinition: relatedEntity);
    }

    if (relatedEntity == null) return false;

    final currentUserPubkey = ref.read(currentPubkeySelectorProvider);

    return relatedEntity.masterPubkey == currentUserPubkey;
  }

  bool _isOwnToken(
    WidgetRef ref, {
    required CommunityTokenDefinitionEntity tokenDefinition,
  }) {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentPubkey == null) return false;

    final data = tokenDefinition.data;
    return data is CommunityTokenDefinitionIon && data.eventReference.masterPubkey == currentPubkey;
  }
}
