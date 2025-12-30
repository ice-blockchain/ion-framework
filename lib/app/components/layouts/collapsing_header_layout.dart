// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

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
    this.pinnedHeader,
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
  final Widget? pinnedHeader;

  /// When `onRefresh` is provided, this layout uses a `NestedScrollView`.
  /// This callback exposes the INNER (body) scroll controller.
  final ValueChanged<ScrollController>? onInnerScrollController;

  double get paddingTop => 60.0.s;

  Widget _buildScrollView(
    BuildContext context, {
    required ScrollController scrollController,
    required AvatarColors? imageColors,
    required Widget child,
    required double scrollOffset,
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

    final pinnedHeaderSliver = pinnedHeader != null
        ? SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHeaderDelegate(
              child: pinnedHeader!,
              scrollOffset: scrollOffset,
            ),
          )
        : null;

    if (onRefresh != null) {
      return NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          final slivers = <Widget>[
            headerSliver,
            SliverToBoxAdapter(
              child: SectionSeparator(
                color: context.theme.appColors.forest,
              ),
            ),
          ];
          if (pinnedHeaderSliver != null) {
            slivers.add(pinnedHeaderSliver);
          }
          return slivers;
        },
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

    final slivers = <Widget>[
      headerSliver,
      SliverToBoxAdapter(
        child: SectionSeparator(
          color: context.theme.appColors.forest,
        ),
      ),
    ];
    if (pinnedHeaderSliver != null) {
      slivers.add(pinnedHeaderSliver);
    }
    slivers.add(SliverToBoxAdapter(child: child));

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      controller: scrollController,
      slivers: slivers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: paddingTop);
    final scrollOffset = useState<double>(0);

    useEffect(
      () {
        void onScroll() {
          scrollOffset.value = scrollController.offset;
        }

        scrollController.addListener(onScroll);
        return () => scrollController.removeListener(onScroll);
      },
      [scrollController],
    );

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
                    context,
                    scrollController: scrollController,
                    imageColors: imageColors,
                    child: child,
                    scrollOffset: scrollOffset.value,
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

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.child,
    required this.scrollOffset,
  });

  final Widget child;
  final double scrollOffset;

  double get _childHeight => _getHeight(child);

  double get _pinnedOffset =>
      NavigationAppBar.screenHeaderHeight +
      PlatformDispatcher.instance.views.first.padding.top /
          PlatformDispatcher.instance.views.first.devicePixelRatio;

  double get _startOffset => 169.0.s;

  double get _currentOffset {
    if (scrollOffset <= _startOffset) return 0;

    final progress = ((scrollOffset - _startOffset) / _pinnedOffset).clamp(0.0, 1.0);

    return _pinnedOffset * progress;
  }

  @override
  double get minExtent => _childHeight + _currentOffset;

  @override
  double get maxExtent => _childHeight + _currentOffset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: context.theme.appColors.forest,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: _currentOffset),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedHeaderDelegate oldDelegate) {
    return scrollOffset != oldDelegate.scrollOffset || child != oldDelegate.child;
  }

  double _getHeight(Widget widget) {
    if (widget is SizedBox && widget.height != null) {
      return widget.height!;
    }
    return 40.0.s;
  }
}
