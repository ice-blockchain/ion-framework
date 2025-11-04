// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/features/components/entities_list/entities_list_skeleton.dart';
import 'package:ion/app/features/feed/notifications/data/model/notifications_tab_type.dart';
import 'package:ion/app/features/feed/notifications/providers/paginated_notifications_provider.r.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_item.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/tabs/empty_list.dart';

class NotificationsTab extends HookConsumerWidget {
  const NotificationsTab({
    required this.type,
    super.key,
  });

  final NotificationsTabType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final paginatedState = ref.watch(paginatedNotificationsProvider(type));
    final paginatedNotifier = ref.watch(paginatedNotificationsProvider(type).notifier);

    return LoadMoreBuilder(
      slivers: [
        if (paginatedState.isInitialLoading)
          const EntitiesListSkeleton()
        else if (paginatedState.notifications.isEmpty && !paginatedState.isLoading)
          const EmptyState()
        else
          SliverList.builder(
            itemCount: paginatedState.notifications.length,
            itemBuilder: (context, index) {
              return NotificationItem(
                key: ValueKey(paginatedState.notifications[index]),
                notification: paginatedState.notifications[index],
                onNotificationHidden: paginatedNotifier.registerHiddenNotification,
              );
            },
          ),
      ],
      onLoadMore: paginatedNotifier.loadMore,
      hasMore: paginatedState.hasMore,
      builder: (context, slivers) => PullToRefreshBuilder(
        onRefresh: paginatedNotifier.refresh,
        builder: (_, slivers) => CustomScrollView(slivers: slivers),
        slivers: slivers,
      ),
    );
  }
}
