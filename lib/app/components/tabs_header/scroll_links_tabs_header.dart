// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/tabs_header/tabs_header_tab.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';

/// A tab bar that scrolls to sections instead of switching tab content.
/// Works like HTML anchor links - tapping a tab scrolls to the corresponding section.
class ScrollLinksTabsHeader extends StatelessWidget {
  const ScrollLinksTabsHeader({
    required this.tabs,
    required this.sectionKeys,
    required this.activeIndex,
    this.scrollDuration = const Duration(milliseconds: 300),
    this.scrollCurve = Curves.easeInOut,
    this.onTabTapped,
    super.key,
  });

  final List<TabType> tabs;
  final List<GlobalKey> sectionKeys;
  final ValueNotifier<int> activeIndex;
  final Duration scrollDuration;
  final Curve scrollCurve;
  final ValueChanged<int>? onTabTapped;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: activeIndex,
      builder: (context, currentIndex, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 6.0.s),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isActive = index == currentIndex;
              return _ScrollLinkTab(
                tabType: tabs[index],
                isActive: isActive,
                onTap: () => _scrollToSection(index),
              );
            }),
          ),
        );
      },
    );
  }

  void _scrollToSection(int index) {
    final key = sectionKeys[index];
    final sectionContext = key.currentContext;

    if (sectionContext != null) {
      // TODO: not clean implementation, fix it (temproary solution)
      // Optimistic update: notify controller to activate tab immediately
      // This provides instant UI feedback before scroll completes
      onTabTapped?.call(index);

      // If no callback provided, fallback to direct update
      if (onTabTapped == null) {
        activeIndex.value = index;
      }

      // Then scroll to the section
      Scrollable.ensureVisible(
        sectionContext,
        duration: scrollDuration,
        curve: scrollCurve,
      );
    }
  }
}

class _ScrollLinkTab extends StatelessWidget {
  const _ScrollLinkTab({
    required this.tabType,
    required this.isActive,
    required this.onTap,
  });

  final TabType tabType;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.theme.appColors.primaryAccent;
    final inactiveColor = context.theme.appColors.tertiaryText;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0.s),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 2.s,
            ),
          ),
        ),
        child: IconTheme(
          data: IconThemeData(color: isActive ? activeColor : inactiveColor),
          child: TabsHeaderTab(tabType: tabType),
        ),
      ),
    );
  }
}
