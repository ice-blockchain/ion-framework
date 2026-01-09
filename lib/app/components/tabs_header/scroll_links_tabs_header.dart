// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/tabs_header/tabs_header_tab.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';

// A tab bar that scrolls to sections instead of switching tab content.
// Works like HTML anchor links - tapping a tab scrolls to the corresponding section.
class ScrollLinksTabsHeader extends HookConsumerWidget {
  const ScrollLinksTabsHeader({
    required this.tabs,
    required this.activeIndex,
    this.onTabTapped,
    super.key,
  });

  final List<TabType> tabs;
  final int activeIndex;
  final ValueChanged<int>? onTabTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(
      initialLength: tabs.length,
      initialIndex: activeIndex,
    );

    // Sync controller with activeIndex changes from parent
    useEffect(
      () {
        if (tabController.index != activeIndex) {
          tabController.animateTo(activeIndex);
        }
        return null;
      },
      [activeIndex, tabController],
    );

    // Handle tab change listener - notify parent when user taps a tab
    useEffect(
      () {
        void handleTabChange() {
          if (!tabController.indexIsChanging && tabController.index != activeIndex) {
            onTabTapped?.call(tabController.index);
          }
        }

        tabController.addListener(handleTabChange);
        return () {
          tabController.removeListener(handleTabChange);
        };
      },
      [tabController, activeIndex, onTabTapped],
    );

    return TabBar(
      controller: tabController,
      padding: EdgeInsets.symmetric(
        horizontal: 6.0.s,
      ),
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: 10.0.s),
      labelColor: context.theme.appColors.lightBlue,
      unselectedLabelColor: context.theme.appColors.tertiaryText,
      tabs: tabs.map((tabType) {
        return TabsHeaderTab(
          tabType: tabType,
        );
      }).toList(),
      indicatorColor: context.theme.appColors.lightBlue,
      dividerHeight: 0,
    );
  }
}
