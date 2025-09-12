// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

void useFollowNotifications(
  BuildContext context,
  WidgetRef ref,
  String pubkey,
  String username,
) {
  ref.listen(
    isCurrentUserFollowingSelectorProvider(pubkey),
    (previous, next) {
      if (next) {
        ref.read(messageNotificationNotifierProvider.notifier).show(
              MessageNotification(
                message: context.i18n.follow_user_message(username),
                icon: Assets.svg.iconFollowuser.icon(
                  size: 16.0.s,
                ),
              ),
            );
      }
    },
  );
}
