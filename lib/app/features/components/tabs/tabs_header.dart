// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/tabs/tab_type.dart';
import 'package:ion/app/features/components/tabs/tabs_header_tab.dart';

class TabsHeader<T extends TabType> extends ConsumerWidget {
  const TabsHeader({
    required this.tabTypes,
    super.key,
  });

  final List<T> tabTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBar(
      padding: EdgeInsets.symmetric(
        horizontal: 6.0.s,
      ),
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: 10.0.s),
      labelColor: context.theme.appColors.primaryAccent,
      unselectedLabelColor: context.theme.appColors.tertiaryText,
      tabs: tabTypes.map((tabType) {
        return TabsHeaderTab(
          tabType: tabType,
        );
      }).toList(),
      indicatorColor: context.theme.appColors.primaryAccent,
      dividerHeight: 0,
    );
  }
}
