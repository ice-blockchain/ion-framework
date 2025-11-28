// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_colored_border.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

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
    final isUserVerified = ref.watch(isUserVerifiedProvider(pubkey));

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
                        key: ValueKey(pubkey),
                        size: width - borderSize * 4,
                        masterPubkey: pubkey,
                      ),
                    ),
                  )
                else
                  IonConnectAvatar(
                    key: ValueKey(pubkey),
                    size: width - borderSize * 2,
                    masterPubkey: pubkey,
                  ),
                if (child != null) child!,
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: context.theme.appTextThemes.caption3.copyWith(
                        color: context.theme.appColors.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUserVerified)
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 2.0.s),
                      child: Assets.svg.iconBadgeVerify.icon(size: 12.0.s),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
