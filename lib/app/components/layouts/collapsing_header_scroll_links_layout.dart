// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/tabs_header/scroll_links_tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

const _kExpandedHeaderContentOffset = -30.0;
const _kTabBarHeight = 48.0;

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
    this.showBackButton = true,
    this.backgroundColor,
    this.externalActiveIndex,
    this.onTabTapped,
    this.floatingActionButton,
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

  /// External active tab controller. If null, layout manages its own state.
  final ValueNotifier<int>? externalActiveIndex;

  /// Optional callback when a tab is tapped manually.
  /// Used for optimistic tab updates (update immediately, not wait for scroll).
  final ValueChanged<int>? onTabTapped;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final internalActiveIndex = useState(0);
    final activeIndex = externalActiveIndex ?? internalActiveIndex;
    final collapseProgress = useState<double>(0);

    useEffect(
      () {
        void onScroll() {
          final offset = scrollController.offset;
          final maxScroll =
              expandedHeaderHeight - NavigationAppBar.screenHeaderHeight - _kTabBarHeight.s;
          final progress = (offset / maxScroll).clamp(0.0, 1.0);

          collapseProgress.value = progress;
        }

        scrollController.addListener(onScroll);
        return () => scrollController.removeListener(onScroll);
      },
      [scrollController],
    );

    // FIXME: DON'T USE HOOKS INSIDE CONDITIONAL BRANCHES
    if (!showBackButton) {
      useScrollTopOnTabPress(context, scrollController: scrollController);
    }

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
                      const _TokenizedCommunityGradient(),
                      Opacity(
                        opacity: 1 - progress, // Fade out as header collapses
                        child: Transform.translate(
                          offset: Offset(0, _kExpandedHeaderContentOffset.s),
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
                preferredSize: Size.fromHeight(_kTabBarHeight.s),
                child: ColoredBox(
                  color: context.theme.appColors.primaryText,
                  child: ScrollLinksTabsHeader(
                    tabs: tabs,
                    sectionKeys: sectionKeys,
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

// Temproary gradient background matching Figma design for tokenized community.
// TODO: change this by gettign the gradient from avatar + black overlay
class _TokenizedCommunityGradient extends StatelessWidget {
  const _TokenizedCommunityGradient();

  // Figma colors
  static const Color _baseColor = Color(0xFF010008);
  static const Color _cyanColor = Color(0xFF017C9F);
  static const Color _magentaColor = Color(0xFF8F039B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _baseColor,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cyan radial gradient (top-left area)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.8, -0.6),
                radius: 1.2,
                colors: [
                  _cyanColor.withValues(alpha: 0.7),
                  _cyanColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Magenta radial gradient (right area)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, 0.0),
                radius: 1.2,
                colors: [
                  _magentaColor.withValues(alpha: 0.8),
                  _magentaColor.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Dark gradient at bottom for smooth transition to tab bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _baseColor.withValues(alpha: 0.5),
                  _baseColor,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
