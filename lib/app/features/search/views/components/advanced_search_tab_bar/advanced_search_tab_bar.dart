// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/model/advanced_search_category.dart';
import 'package:ion/app/features/search/views/components/advanced_search_tab/advanced_search_tab.dart';

class AdvancedSearchTabBar extends StatelessWidget {
  const AdvancedSearchTabBar({required this.categories, this.controller, super.key});

  final List<AdvancedSearchCategory> categories;
  final TabController? controller;

  static double get _tabItemHorizontalGap => 16.0.s;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSideOffset.defaultSmallMargin - _tabItemHorizontalGap / 2,
      ),
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: _tabItemHorizontalGap / 2),
      labelColor: context.theme.appColors.primaryAccent,
      unselectedLabelColor: context.theme.appColors.tertiaryText,
      tabs: categories.map((category) {
        return AdvancedSearchTab(category: category);
      }).toList(),
      indicatorColor: context.theme.appColors.primaryAccent,
      dividerHeight: 0,
    );
  }
}
