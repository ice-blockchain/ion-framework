// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';

class CollapsingAppBar extends StatelessWidget {
  CollapsingAppBar({
    required this.child,
    required this.height,
    super.key,
    double? bottomOffset,
    double? topOffset,
  })  : bottomOffset = bottomOffset ?? 10.0.s,
        topOffset = topOffset ?? ScreenTopOffset.defaultMargin;

  final Widget child;
  final double height;
  final double bottomOffset;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    final safeAreaOffset = MediaQuery.paddingOf(context).top;
    final totalHeight = height + topOffset + bottomOffset + safeAreaOffset;
    print('CollapsingAppBar totalHeight: $totalHeight');
    final fadeOffset = totalHeight - topOffset - safeAreaOffset;
    print('CollapsingAppBar fadeOffset: $fadeOffset');

    return SliverAppBar(
      floating: true,
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: height + topOffset + bottomOffset,
      shadowColor: context.theme.appColors.onTertiaryBackground.withValues(alpha: 0.05),
      toolbarHeight: 0,
      backgroundColor: context.theme.appColors.onPrimaryAccent,
      surfaceTintColor: context.theme.appColors.onPrimaryAccent,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final overlayOpacity = ((totalHeight - constraints.maxHeight) / fadeOffset).clamp(0, 1);
          print('CollapsingAppBar overlayOpacity: $overlayOpacity');
          return Align(
            alignment: Alignment.bottomCenter,
            child: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: //.child,
                  Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: bottomOffset),
                    child: IgnorePointer(
                      // ignoring: false,
                      ignoring: overlayOpacity > 0.5,
                      child: child,
                    ),
                  ),
                  Positioned.fill(
                    child: ColoredBox(
                      color: context.theme.appColors.onPrimaryAccent
                          .withValues(alpha: overlayOpacity.toDouble()),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
