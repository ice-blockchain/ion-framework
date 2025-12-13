// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/tabs_header/tabs_header_tab.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';

class TabsHeader extends ConsumerWidget {
  const TabsHeader({
    required this.tabs,
    this.trailing,
    super.key,
  });

  final List<TabType> tabs;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabBar = TabBar(
      padding: EdgeInsets.symmetric(
        horizontal: 6.0.s,
      ),
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: 10.0.s),
      labelColor: context.theme.appColors.primaryAccent,
      unselectedLabelColor: context.theme.appColors.tertiaryText,
      tabs: tabs.map((tabType) {
        return TabsHeaderTab(
          tabType: tabType,
        );
      }).toList(),
      indicatorColor: context.theme.appColors.primaryAccent,
      dividerHeight: 0,
    );

    if (trailing == null) {
      return tabBar;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: tabBar,
        ),
        trailing!,
      ],
    );
  }
}
