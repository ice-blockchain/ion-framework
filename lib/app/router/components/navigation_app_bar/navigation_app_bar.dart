// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';

class NavigationAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const NavigationAppBar({
    required this.useScreenTopOffset,
    this.title,
    this.showBackButton = true,
    this.hideKeyboardOnBack = false,
    this.applyHitSlop = true,
    this.onBackPress,
    this.actions,
    this.leading,
    this.scrollController,
    this.backgroundColor,
    super.key,
  });

  factory NavigationAppBar.screen({
    Widget? title,
    bool showBackButton = true,
    VoidCallback? onBackPress,
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
    Key? key,
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
      );

  factory NavigationAppBar.modal({
    Widget? title,
    bool showBackButton = true,
    VoidCallback? onBackPress,
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
      );

  factory NavigationAppBar.root({
    Widget? title,
    List<Widget>? actions,
    bool applyHitSlop = true,
    ScrollController? scrollController,
  }) =>
      NavigationAppBar(
        title: title,
        actions: actions,
        useScreenTopOffset: true,
        showBackButton: false,
        applyHitSlop: applyHitSlop,
        scrollController: scrollController,
      );

  static double get modalHeaderHeight => 60.0.s;

  static double get screenHeaderHeight => 56.0.s;

  static double get actionButtonSide => 24.0.s;

  final Widget? title;
  final bool showBackButton;
  final bool hideKeyboardOnBack;
  final bool applyHitSlop;
  final VoidCallback? onBackPress;
  final List<Widget>? actions;
  final bool useScreenTopOffset;
  final Widget? leading;
  final Color? backgroundColor;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasScrolled = useState(false);
    if (scrollController != null) {
      useEffect(
        () {
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
    }

    final Widget? titleWidget = title != null
        ? DefaultTextStyle(
            textAlign: TextAlign.center,
            style: context.theme.appTextThemes.subtitle
                .copyWith(color: context.theme.appColors.primaryText),
            child: title!,
          )
        : null;

    final effectiveTrailing = actions != null && actions!.isNotEmpty
        ? Padding(
            padding: EdgeInsetsDirectional.only(
              end: ScreenSideOffset.defaultSmallMargin - UiConstants.hitSlop,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
          )
        : null;

    final Widget appBarContent = NavigationToolbar(
      middleSpacing: 0,
      leading: leading ??
          (showBackButton
              ? NavigationBackButton(
                  () => (onBackPress ?? context.pop)(),
                  hideKeyboardOnBack: hideKeyboardOnBack,
                )
              : null),
      middle: titleWidget,
      trailing: effectiveTrailing,
    );

    final Widget appBar = Container(
      height: useScreenTopOffset ? screenHeaderHeight : modalHeaderHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.theme.appColors.secondaryBackground,
        boxShadow: hasScrolled.value
            ? [
                BoxShadow(
                  color: context.theme.appColors.onTertiaryBackground.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: applyHitSlop
              ? ScreenSideOffset.defaultSmallMargin - UiConstants.hitSlop
              : ScreenSideOffset.defaultSmallMargin,
        ),
        child: appBarContent,
      ),
    );

    return useScreenTopOffset
        ? ScreenTopOffset(
            margin: 0,
            child: appBar,
          )
        : appBar;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        useScreenTopOffset ? screenHeaderHeight : modalHeaderHeight,
      );
}
