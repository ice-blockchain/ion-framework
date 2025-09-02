// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_colored_border.dart';

class StoryItemContent extends HookConsumerWidget {
  const StoryItemContent({
    required this.pubkey,
    required this.name,
    required this.onTap,
    this.gradient,
    this.isViewed = false,
    this.child,
    super.key,
  });

  final String pubkey;
  final String name;
  final Gradient? gradient;
  final VoidCallback onTap;
  final bool isViewed;
  final Widget? child;

  static double get width => 65.0.s;
  static double get height => 91.0.s;
  static double get borderSize => 2.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                if (gradient != null)
                  StoryColoredBorder(
                    size: width,
                    color: context.theme.appColors.strokeElements,
                    gradient: gradient,
                    isViewed: isViewed,
                    child: StoryColoredBorder(
                      size: width - borderSize * 2,
                      color: context.theme.appColors.secondaryBackground,
                      child: IonConnectAvatar(
                        size: width - borderSize * 4,
                        pubkey: pubkey,
                        cached: true,
                      ),
                    ),
                  )
                else
                  IonConnectAvatar(
                    size: width - borderSize * 2,
                    pubkey: pubkey,
                    cached: true,
                  ),
                if (child != null) child!,
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0.s),
              child: Text(
                name,
                style: context.theme.appTextThemes.caption3.copyWith(
                  color: context.theme.appColors.primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
