// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_loading.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/username_text_span.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_tap_gesture_recognizer.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/l10n/i10n.dart';

class MentionNotificationInfo extends HookConsumerWidget {
  const MentionNotificationInfo({
    required this.notification,
    super.key,
  });

  final MentionIonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubkey = notification.eventReference.masterPubkey;
    final userData = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    final recognizer = useTapGestureRecognizer(
      onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
    );

    if (userData == null) {
      return const NotificationInfoLoading();
    }

    final description = context.i18n.notifications_mentioned;

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
    );
  }
}
