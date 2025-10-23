// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/gradient_border_painter/gradient_border_painter.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ShareTokenCreatorPage extends ConsumerWidget {
  const ShareTokenCreatorPage({
    required this.masterPubkey,
    super.key,
  });

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(masterPubkey)).valueOrNull;

    final gradient = storyBorderGradients[Random().nextInt(storyBorderGradients.length)];
    return SheetContent(
      bottomPadding: 0,
      body: SizedBox(
        height: 400.s + MediaQuery.paddingOf(context).bottom,
        child: Stack(
          children: [
            const ProfileBackground(),
            Positioned.fill(
              child: SvgPicture.asset(
                Assets.svg.radiatingLight,
                fit: BoxFit.fill,
              ),
            ),
            // Close Button
            PositionedDirectional(
              top: 16.0.s,
              end: 16.0.s,
              child: NavigationCloseButton(
                color: context.theme.appColors.onPrimaryAccent,
              ),
            ),
            // Profile Info Overlay
            PositionedDirectional(
              bottom: 0,
              top: 60.s,
              start: 0,
              end: 0,
              child: Column(
                children: [
                  // Avatar
                  CustomPaint(
                    painter: GradientBorderPainter(
                      gradient: LinearGradient(
                        colors: gradient.colors,
                      ),
                      strokeWidth: 2.s,
                      cornerRadius: 26.s,
                    ),
                    child: Container(
                      height: 100.s,
                      width: 100.s,
                      decoration: ShapeDecoration(
                        color: context.theme.appColors.primaryText.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.s),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Avatar
                          Center(
                            child: Avatar(
                              size: 64.0.s,
                              imageUrl: userMetadata?.data.avatarUrl,
                            ),
                          ),
                          // LIVE Button
                          PositionedDirectional(
                            bottom: -8.s,
                            start: 0,
                            end: 0,
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.s, vertical: 1.s),
                                decoration: ShapeDecoration(
                                  color: context.theme.appColors.success,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.s),
                                  ),
                                ),
                                child: Text(
                                  context.i18n.wallet_share_token_creator_live_status,
                                  style: context.theme.appTextThemes.body.copyWith(
                                    color: context.theme.appColors.onPrimaryAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12.0.s),
                  // User Name
                  UserNameTile(pubkey: masterPubkey, profileMode: ProfileMode.dark),
                  SizedBox(height: 24.0.s),
                  // Creator Token Live Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.i18n.wallet_share_token_creator_title,
                        style: context.theme.appTextThemes.title.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.0.s),
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(horizontal: 50.s),
                        child: Text(
                          context.i18n.wallet_share_token_creator_description,
                          textAlign: TextAlign.center,
                          style: context.theme.appTextThemes.caption2.copyWith(
                            color: context.theme.appColors.attentionBlock,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.0.s),
                  // Share Button
                  ScreenSideOffset.small(
                    child: Button(
                      mainAxisSize: MainAxisSize.max,
                      label: Text(
                        context.i18n.wallet_share_token_creator_button,
                        style: context.theme.appTextThemes.body.copyWith(
                          color: context.theme.appColors.onPrimaryAccent,
                        ),
                      ),
                      backgroundColor: context.theme.appColors.primaryAccent,
                      borderColor: Colors.transparent,
                      minimumSize: Size(double.infinity, 48.0.s),
                      onPressed: () {
                        // TODO: Implement share functionality
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
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
