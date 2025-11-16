// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';

class NavigationAppBar extends HookWidget implements PreferredSizeWidget {
  const NavigationAppBar({
    required this.useScreenTopOffset,
    this.title,
    this.showBackButton = true,
    this.hideKeyboardOnBack = false,
    this.horizontalPadding,
    this.onBackPress,
    this.actions,
    this.leading,
    this.scrollController,
    this.backgroundColor,
    this.backButtonIcon,
    this.extendBehindStatusBar = false,
    this.backgroundBuilder,
    super.key,
  });

  factory NavigationAppBar.screen({
    Widget? title,
    bool showBackButton = true,
    VoidCallback? onBackPress,
    double? horizontalPadding,
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
    Key? key,
    ScrollController? scrollController,
  }) =>
      NavigationAppBar(
        title: title,
        showBackButton: showBackButton,
        onBackPress: onBackPress,
        actions: actions,
        useScreenTopOffset: true,
        leading: leading,
        backgroundColor: backgroundColor,
        key: key,
        scrollController: scrollController,
        horizontalPadding: horizontalPadding,
      );

  factory NavigationAppBar.modal({
    Widget? title,
    bool showBackButton = true,
    VoidCallback? onBackPress,
    double? horizontalPadding,
    List<Widget>? actions,
    bool hideKeyboardOnBack = true,
    Widget? leading,
    Key? key,
  }) =>
      NavigationAppBar(
        title: title,
        showBackButton: showBackButton,
        onBackPress: onBackPress,
        actions: actions,
        useScreenTopOffset: false,
        hideKeyboardOnBack: hideKeyboardOnBack,
        leading: leading,
        key: key,
        horizontalPadding: horizontalPadding,
      );

  factory NavigationAppBar.root({
    Widget? title,
    List<Widget>? actions,
    double? horizontalPadding,
    ScrollController? scrollController,
  }) =>
      NavigationAppBar(
        title: title,
        actions: actions,
        useScreenTopOffset: true,
        showBackButton: false,
        horizontalPadding: horizontalPadding,
        scrollController: scrollController,
      );

  static double get modalHeaderHeight => 60.0.s;

  static double get screenHeaderHeight => 56.0.s;

  static double get actionButtonSide => 24.0.s;

  final Widget? title;
  final bool showBackButton;
  final bool hideKeyboardOnBack;
  final double? horizontalPadding;
  final VoidCallback? onBackPress;
  final List<Widget>? actions;
  final bool useScreenTopOffset;
  final Widget? leading;
  final Color? backgroundColor;
  final ScrollController? scrollController;
  final Widget? backButtonIcon;
  final bool extendBehindStatusBar;
  final Widget Function()? backgroundBuilder;

  @override
  Widget build(BuildContext context) {
    final hasScrolled = useState(false);
    useEffect(
      () {
        if (scrollController == null) return () {};

        void scrollListener() {
          final newHasScrolled = scrollController!.offset > 0;
          if (hasScrolled.value != newHasScrolled) {
            hasScrolled.value = newHasScrolled;
          }
        }

        scrollController!.addListener(scrollListener);
        return () => scrollController!.removeListener(scrollListener);
      },
      [scrollController],
    );

    final Widget? titleWidget = title != null
        ? DefaultTextStyle(
            textAlign: TextAlign.center,
            style: context.theme.appTextThemes.subtitle
                .copyWith(color: context.theme.appColors.primaryText),
            child: title!,
          )
        : null;

    final effectiveTrailing = actions != null && actions!.isNotEmpty
        ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
        : null;

    // Set back button color for modal (when useScreenTopOffset is false)
    final backButtonColor = !useScreenTopOffset ? context.theme.appColors.tertiaryText : null;

    final Widget appBarContent = NavigationToolbar(
      middleSpacing: 0,
      leading: leading ??
          (showBackButton
              ? NavigationBackButton(
                  () => (onBackPress ?? context.maybePop)(),
                  hideKeyboardOnBack: hideKeyboardOnBack,
                  color: backButtonColor,
                  icon: backButtonIcon,
                )
              : null),
      middle: titleWidget,
      trailing: effectiveTrailing,
    );
    final baseHeight = useScreenTopOffset ? screenHeaderHeight : modalHeaderHeight;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final topPadding = extendBehindStatusBar ? statusBarHeight : 0.0;
    final totalHeight = extendBehindStatusBar ? baseHeight + statusBarHeight : baseHeight;

    final Widget appBar = Stack(
      children: [
        if (backgroundBuilder != null) Positioned.fill(child: backgroundBuilder!()),
        Container(
          height: totalHeight,
          decoration: BoxDecoration(
            color: backgroundBuilder != null
                ? null
                : (backgroundColor ?? context.theme.appColors.secondaryBackground),
            boxShadow: hasScrolled.value
                ? [
                    BoxShadow(
                      color: context.theme.appColors.shadow.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: topPadding,
              start: horizontalPadding ?? ScreenSideOffset.defaultSmallMargin - UiConstants.hitSlop,
              end: horizontalPadding ?? ScreenSideOffset.defaultSmallMargin - UiConstants.hitSlop,
            ),
            child: appBarContent,
          ),
        ),
      ],
    );

    if (extendBehindStatusBar || !useScreenTopOffset) {
      return appBar;
    }

    return ScreenTopOffset(
      margin: 0,
      child: appBar,
    );
  }

  @override
  Size get preferredSize {
    final baseHeight = useScreenTopOffset ? screenHeaderHeight : modalHeaderHeight;
    return Size.fromHeight(baseHeight);
  }
}
