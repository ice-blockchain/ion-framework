// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/pages/turn_on_notifications/descriptions.dart';
import 'package:ion/app/features/auth/views/pages/turn_on_notifications/notifications.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';

class ShowTurnOnNotificationsEvent extends UiEvent {
  const ShowTurnOnNotificationsEvent() : super(id: 'turn_on_notifications');

  @override
  Future<void> performAction(BuildContext context) async {
    await context.push<void>(NotificationsRoute().location);
  }
}

class TurnOnNotifications extends ConsumerWidget {
  const TurnOnNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: AuthScrollContainer(
        title: context.i18n.turn_notifications_title,
        description: context.i18n.turn_notifications_description,
        showBackButton: false,
        children: [
          Column(
            children: [
              SizedBox(height: 28.0.s),
              const Notifications(),
              SizedBox(height: 24.0.s),
              const Descriptions(),
              SizedBox(height: 24.0.s),
            ],
          ),
          Padding(
            padding:
                EdgeInsetsDirectional.only(bottom: 8.0.s + MediaQuery.paddingOf(context).bottom),
            child: ScreenSideOffset.small(
              child: Button(
                label: Text(context.i18n.button_continue),
                mainAxisSize: MainAxisSize.max,
                onPressed: () async {
                  await ref
                      .read(permissionsProvider.notifier)
                      .requestPermission(Permission.notifications);
                  if (context.mounted) {
                    FeedRoute().go(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
