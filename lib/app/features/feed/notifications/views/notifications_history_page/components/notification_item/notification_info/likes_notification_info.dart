// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/username_text_span.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_tap_gesture_recognizer.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/l10n/i10n.dart';

class LikesNotificationInfo extends HookConsumerWidget {
  const LikesNotificationInfo({
    required this.notification,
    super.key,
  });

  final LikesIonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubkeys = notification.pubkeys;
    final recognizers = useTapGestureRecognizers();
    final eventTypeLabel = _getEventTypeLabel(ref);

    final userDatas = pubkeys.take(pubkeys.length == 2 ? 2 : 1).map((pubkey) {
      return ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    }).toList();

    if (userDatas.contains(null)) {
      return const SizedBox.shrink();
    }

    final description = switch (pubkeys.length) {
      1 => context.i18n.notifications_liked_one(eventTypeLabel),
      2 => context.i18n.notifications_liked_two(eventTypeLabel),
      _ => context.i18n.notifications_liked_many(notification.total - 1, eventTypeLabel),
    };

    final textSpan = replaceString(
      description,
      tagRegex('username'),
      (match, index) {
        final pubkey = pubkeys.elementAtOrNull(index);
        final userData = userDatas.elementAtOrNull(index);
        if (pubkey == null || userData == null) {
          return const TextSpan(text: '');
        }
        final recognizer = TapGestureRecognizer()
          ..onTap = () => ProfileRoute(pubkey: pubkey).push<void>(context);
        recognizers.add(recognizer);
        final displayName = userData.data.trimmedDisplayName.isEmpty
            ? userData.data.name
            : userData.data.trimmedDisplayName;
        return buildUsernameTextSpan(
          context,
          displayName: displayName,
          recognizer: recognizer,
        );
      },
    );

    return NotificationInfoText(
      textSpan: textSpan,
      timestamp: notification.timestamp,
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
      CommunityTokenActionEntity() => ref.context.i18n.notifications_post,
      _ => '',
    };
  }

  IonConnectEntity? _getRelatedEntity(WidgetRef ref) {
    final eventReference = notification.eventReference;

    final entity = ref.watch(
      ionConnectSyncEntityWithCountersProvider(
        eventReference: eventReference,
      ),
    );

    return entity;
  }
}
