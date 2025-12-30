// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class CollapsingHeaderLayout extends HookWidget {
  const CollapsingHeaderLayout({
    required this.imageUrl,
    required this.expandedHeader,
    required this.child,
    required this.collapsedHeaderBuilder,
    required this.headerActionsBuilder,
    required this.floatingActionButton,
    this.newUiMode = true,
    this.showBackButton = true,
    this.backgroundColor,
    this.applySafeAreaBottomPadding = true,
    this.onBackButtonPressed,
    this.onRefresh,
    this.onInnerScrollController,
    super.key,
  });

  final String? imageUrl;
  final bool showBackButton;
  final bool newUiMode;
  final Widget expandedHeader;
  final Widget child;
  final Widget Function(double opacity) collapsedHeaderBuilder;
  final List<Widget> Function(OverlayMenuCloseSignal menuCloseSignal) headerActionsBuilder;
  final Color? backgroundColor;
  final bool applySafeAreaBottomPadding;
  final VoidCallback? onBackButtonPressed;
  final Widget floatingActionButton;
  final Future<void> Function()? onRefresh;

  /// When `onRefresh` is provided, this layout uses a `NestedScrollView`.
  /// This callback exposes the INNER (body) scroll controller.
  final ValueChanged<ScrollController>? onInnerScrollController;

  double get paddingTop => 60.0.s;

  Widget _buildScrollView({
    required ScrollController scrollController,
    required AvatarColors? imageColors,
    required Widget child,
  }) {
    final headerSliver = SliverToBoxAdapter(
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
    );

    if (onRefresh != null) {
      return NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          headerSliver,
          const SliverToBoxAdapter(child: SectionSeparator()),
        ],
        body: Builder(
          builder: (context) {
            final innerController = PrimaryScrollController.maybeOf(context);
            if (innerController != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onInnerScrollController?.call(innerController);
              });
            }

            return PullToRefreshBuilder(
              onRefresh: onRefresh!,
              builder: (context, slivers) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                primary: true,
                slivers: slivers,
              ),
              slivers: [SliverToBoxAdapter(child: child)],
            );
          },
        ),
      );
    }

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      controller: scrollController,
      slivers: [
        headerSliver,
        const SliverToBoxAdapter(child: SectionSeparator()),
        SliverToBoxAdapter(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: paddingTop);

    final imageColors = useImageColors(imageUrl);
    final backgroundColor = this.backgroundColor ?? context.theme.appColors.secondaryBackground;

    final showAppBarBackground = opacity > 0.5;

    final menuCloseSignal = useMemoized(OverlayMenuCloseSignal.new);
    useEffect(() => menuCloseSignal.dispose, [menuCloseSignal]);

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
      color: newUiMode ? context.theme.appColors.onPrimaryAccent : null,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              left: !newUiMode,
              right: !newUiMode,
              top: !newUiMode,
              bottom: applySafeAreaBottomPadding,
              child: NotificationListener(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) {
                    menuCloseSignal.trigger();
                  }
                  return true;
                },
                child: ColoredBox(
                  color: backgroundColor,
                  child: _buildScrollView(
                    scrollController: scrollController,
                    imageColors: imageColors,
                    child: child,
                  ),
                ),
              ),
            ),
            NavigationAppBar(
              showBackButton: showBackButton,
              useScreenTopOffset: true,
              extendBehindStatusBar: newUiMode,
              backButtonIcon: backButtonIcon,
              scrollController: scrollController,
              horizontalPadding: 0,
              backgroundColor:
                  showAppBarBackground ? (newUiMode ? null : backgroundColor) : Colors.transparent,
              backgroundBuilder: newUiMode && showAppBarBackground
                  ? () => ProfileBackground(
                        colors: imageColors,
                        disableDarkGradient: true,
                      )
                  : null,
              title: IgnorePointer(
                ignoring: opacity <= 0.5,
                child: Opacity(
                  opacity: opacity,
                  child: collapsedHeaderBuilder(opacity),
                ),
              ),
              actions: headerActionsBuilder(menuCloseSignal).asMap().entries.map((entry) {
                final action = entry.value;
                return action;
              }).toList(),
              onBackPress: onBackButtonPressed,
            ),
          ],
        ),
      ),
    );
  }
}
