// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/notifications/providers/unread_notifications_count_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_button/navigation_button.dart';
import 'package:ion/generated/assets.gen.dart';

class FeedNotificationsButton extends ConsumerWidget {
  const FeedNotificationsButton({super.key});

  static double get counterOffset => 5.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // List on NotificationTab page is destroyed when we leave the page,
    // but we have to keep blocked users entities for quick access
    return ListCachedObjectsWrapper(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          NavigationButton(
            onPressed: () => NotificationsHistoryRoute().push<void>(context),
            icon: Assets.svg.iconHomeNotification.icon(
              color: context.theme.appColors.primaryText,
            ),
          ),
          PositionedDirectional(
            top: -counterOffset,
            end: -counterOffset,
            child: const _UnreadCounter(),
          ),
        ],
      ),
    );
  }
}

class _UnreadCounter extends ConsumerWidget {
  const _UnreadCounter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull;

    if (unreadCount == null || unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.s, vertical: 2.5.s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0.s),
        color: context.theme.appColors.attentionRed,
      ),
      constraints: BoxConstraints(minWidth: 20.0.s),
      child: Text(
        unreadCount.toString(),
        textAlign: TextAlign.center,
        style: context.theme.appTextThemes.caption5.copyWith(
          color: context.theme.appColors.primaryBackground,
        ),
      ),
    );
  }
}
