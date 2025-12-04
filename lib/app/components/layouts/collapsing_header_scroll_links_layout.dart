// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/tabs_header/scroll_links_tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

// A layout with collapsing header and scroll-link tabs using SliverAppBar.
// Tabs scroll to sections instead of switching content (like HTML anchor links).
// Tab bar properly pins below the app bar when scrolled.
class CollapsingHeaderScrollLinksLayout extends HookWidget {
  const CollapsingHeaderScrollLinksLayout({
    required this.tabs,
    required this.expandedHeader,
    required this.expandedHeaderHeight,
    required this.sectionKeys,
    required this.sectionsBuilder,
    required this.collapsedTitle,
    required this.actions,
    required this.activeIndex,
    this.showBackButton = true,
    this.backgroundColor,
    this.onTabTapped,
    this.floatingActionButton,
    this.imageUrl,
    super.key,
  });

  final bool showBackButton;
  final Widget expandedHeader;
  final double expandedHeaderHeight;
  final List<TabType> tabs;
  final List<GlobalKey> sectionKeys;
  final List<Widget> Function(List<GlobalKey> sectionKeys) sectionsBuilder;
  final Widget collapsedTitle;
  final List<Widget> actions;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final int activeIndex;
  final String? imageUrl;

  final ValueChanged<int>? onTabTapped;

  double get _expandedHeaderContentOffset => -30.0.s;
  double get _tabBarHeight => 48.0.s;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final collapseProgress = useState<double>(0);
    final avatarColors = useImageColors(imageUrl);

    useEffect(
      () {
        void onScroll() {
          final offset = scrollController.offset;
          final maxScroll =
              expandedHeaderHeight - NavigationAppBar.screenHeaderHeight - _tabBarHeight;
          final progress = (offset / maxScroll).clamp(0.0, 1.0);

          collapseProgress.value = progress;
        }

        scrollController.addListener(onScroll);
        return () => scrollController.removeListener(onScroll);
      },
      [scrollController],
    );

    final sections = sectionsBuilder(sectionKeys);

    return Scaffold(
      backgroundColor: backgroundColor ?? context.theme.appColors.secondaryBackground,
      floatingActionButton: floatingActionButton,
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedHeaderHeight,
              toolbarHeight: NavigationAppBar.screenHeaderHeight,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: showBackButton
                  ? NavigationBackButton(
                      context.pop,
                      icon: Assets.svg.iconProfileBack.icon(
                        size: NavigationBackButton.iconSize,
                        color: context.theme.appColors.onPrimaryAccent,
                      ),
                    )
                  : null,
              actions: actions,
              title: ValueListenableBuilder<double>(
                valueListenable: collapseProgress,
                builder: (context, progress, child) {
                  return Opacity(
                    opacity: progress, // Fade in as header collapses
                    child: child,
                  );
                },
                child: collapsedTitle,
              ),
              centerTitle: false,
              titleSpacing: 0,
              flexibleSpace: ValueListenableBuilder<double>(
                valueListenable: collapseProgress,
                builder: (context, progress, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ProfileBackground(
                        colors: avatarColors,
                      ),
                      Opacity(
                        opacity: 1 - progress, // Fade out as header collapses
                        child: Transform.translate(
                          offset: Offset(0, _expandedHeaderContentOffset),
                          child: SafeArea(
                            bottom: false,
                            child: expandedHeader,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(_tabBarHeight),
                child: ColoredBox(
                  color: context.theme.appColors.primaryText,
                  child: ScrollLinksTabsHeader(
                    tabs: tabs,
                    activeIndex: activeIndex,
                    onTabTapped: onTabTapped,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SectionSeparator()),
            ...sections.map(
              (section) => SliverToBoxAdapter(child: section),
            ),
          ],
        ),
      ),
    );
  }
}
