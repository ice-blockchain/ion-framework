// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/model/notifications_tab_type.dart';
import 'package:ion/app/features/feed/notifications/providers/paginated_notifications_provider.r.dart';
import 'package:ion/app/features/feed/notifications/providers/unread_notifications_count_provider.r.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/tabs/notifications_tab.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/tabs_header/tabs_header.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

class NotificationsHistoryPage extends ConsumerStatefulWidget {
  const NotificationsHistoryPage({
    super.key,
  });

  @override
  ConsumerState<NotificationsHistoryPage> createState() => _NotificationsHistoryPageState();
}

class _NotificationsHistoryPageState extends ConsumerState<NotificationsHistoryPage>
    with SingleTickerProviderStateMixin, RestorationMixin {
  late final TabController _tabController;
  final RestorableInt _tabIndex = RestorableInt(0);

  @override
  String? get restorationId => 'notifications_history_tab';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: NotificationsTabType.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markNotificationsRead();
    });
  }

  Future<void> _markNotificationsRead() async {
    await ref.read(unreadNotificationsCountProvider.notifier).readAll();

    final notificationsState = ref.read(
      paginatedNotificationsProvider(NotificationsTabType.all),
    );
    final notifications = notificationsState.notifications;
    if (notifications.isNotEmpty) {
      await ref
          .read(unreadNotificationsCountProvider.notifier)
          .cancelNotifications(notifications);
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _tabIndex.value = _tabController.index;
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tabIndex, 'tab_index');
    _tabController.index = _tabIndex.value;
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(context.i18n.notifications_title),
      ),
      body: ScreenTopOffset(
        child: Column(
          children: [
            NotificationsHistoryTabsHeader(controller: _tabController),
            const SectionSeparator(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: NotificationsTabType.values
                    .map((type) => NotificationsTab(type: type))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
