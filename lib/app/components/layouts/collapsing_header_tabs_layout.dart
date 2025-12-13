// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/tabs_header/tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class CollapsingHeaderTabsLayout extends HookWidget {
  const CollapsingHeaderTabsLayout({
    required this.imageUrl,
    required this.tabs,
    required this.expandedHeader,
    required this.tabBarViews,
    required this.collapsedHeaderBuilder,
    required this.headerActionsBuilder,
    this.newUiMode = true,
    this.showBackButton = true,
    this.backgroundColor,
    this.applySafeAreaBottomPadding = true,
    this.onBackButtonPressed,
    super.key,
  });

  final String? imageUrl;
  final bool showBackButton;
  final bool newUiMode;
  final Widget expandedHeader;
  final List<TabType> tabs;
  final List<Widget> tabBarViews;
  final Widget Function(double opacity) collapsedHeaderBuilder;
  final List<Widget> Function(OverlayMenuCloseSignal menuCloseSignal) headerActionsBuilder;
  final Color? backgroundColor;
  final bool applySafeAreaBottomPadding;
  final VoidCallback? onBackButtonPressed;

  double get paddingTop => 60.0.s;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: paddingTop);

    final imageColors = useImageColors(imageUrl);
    final backgroundColor = this.backgroundColor ?? context.theme.appColors.secondaryBackground;

    final menuCloseSignal = useMemoized(OverlayMenuCloseSignal.new);
    useEffect(() => menuCloseSignal.dispose, [menuCloseSignal]);

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
      color: newUiMode ? context.theme.appColors.onPrimaryAccent : null,
    );

    useScrollTopOnTabPress(
      context,
      scrollController: scrollController,
      enabled: !showBackButton,
    );

    return ScrollToTopWrapper(
      scrollController: scrollController,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            left: !newUiMode,
            right: !newUiMode,
            top: !newUiMode,
            bottom: applySafeAreaBottomPadding,
            child: DefaultTabController(
              length: tabs.length,
              child: NotificationListener(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) {
                    menuCloseSignal.trigger();
                  }
                  return true;
                },
                child: NestedScrollView(
                  controller: scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Stack(
                          children: [
                            if (newUiMode)
                              Positioned.fill(
                                child: ProfileBackground(
                                  colors: imageColors,
                                ),
                              ),
                            expandedHeader,
                          ],
                        ),
                      ),
                      PinnedHeaderSliver(
                        child: ColoredBox(
                          color: newUiMode ? context.theme.appColors.forest : backgroundColor,
                          child: TabsHeader(
                            tabs: tabs,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SectionSeparator()),
                    ];
                  },
                  body: TabBarView(
                    children: tabBarViews,
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: opacity <= 0.5,
            child: Opacity(
              opacity: opacity,
              child: NavigationAppBar(
                showBackButton: showBackButton,
                useScreenTopOffset: true,
                extendBehindStatusBar: newUiMode,
                backButtonIcon: backButtonIcon,
                scrollController: scrollController,
                horizontalPadding: 0,
                backgroundBuilder: newUiMode
                    ? () => ProfileBackground(
                          colors: imageColors,
                          disableDarkGradient: true,
                        )
                    : null,
                title: collapsedHeaderBuilder(opacity),
                actions: headerActionsBuilder(menuCloseSignal).asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  if (index == 0) return action;
                  return Padding(
                    padding: EdgeInsetsDirectional.only(start: 8.0.s, end: 16.0.s),
                    child: action,
                  );
                }).toList(),
                onBackPress: onBackButtonPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
