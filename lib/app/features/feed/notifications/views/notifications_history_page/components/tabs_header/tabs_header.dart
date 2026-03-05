// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/model/notifications_tab_type.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/tabs_header/tabs_header_tab.dart';

class NotificationsHistoryTabsHeader extends ConsumerWidget {
  const NotificationsHistoryTabsHeader({
    this.controller,
    super.key,
  });

  final TabController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBar(
      controller: controller,
      padding: EdgeInsets.symmetric(
        horizontal: 6.0.s,
      ),
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: 10.0.s),
      labelColor: context.theme.appColors.primaryAccent,
      unselectedLabelColor: context.theme.appColors.tertiaryText,
      tabs: NotificationsTabType.values.map((tabType) {
        return NotificationsHistoryTab(
          tabType: tabType,
        );
      }).toList(),
      indicatorColor: context.theme.appColors.primaryAccent,
      dividerHeight: 0,
    );
  }
}
