// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/user/user_about/user_about.dart';
import 'package:ion/app/features/components/user/user_info_summary/user_info_summary.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_dialog.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/relevant_followers/relevant_followers.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';

class ProfileUserInfo extends ConsumerWidget {
  const ProfileUserInfo({
    required this.pubkey,
    required this.profileMode,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));

    final externalAddress = ref.watch(userMetadataProvider(pubkey)).valueOrNull?.externalAddress;

    final info = Column(
      children: [
        if (!isCurrentUserProfile) ...[
          RelevantFollowers(
            pubkey: pubkey,
            profileMode: profileMode,
          ),
          SizedBox(height: 12.0.s),
        ],
        UserAbout(
          pubkey: pubkey,
          padding: EdgeInsetsDirectional.only(bottom: 12.0.s),
          profileMode: profileMode,
        ),
        UserInfoSummary(
          pubkey: pubkey,
          profileMode: profileMode,
        ),
      ],
    );

    if (profileMode == ProfileMode.dark) {
      return Container(
        padding:
            EdgeInsetsDirectional.only(start: 20.0.s, end: 20.0.s, top: 16.0.s, bottom: 16.0.s),
        decoration: ShapeDecoration(
          color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.53.s),
          ),
        ),
        child: Column(
          children: [
            info,
            GradientHorizontalDivider(
              margin: EdgeInsetsDirectional.symmetric(vertical: 12.5.s),
            ),
            if (externalAddress != null)
              Row(
                children: [
                  Expanded(
                    child: ProfileTokenStats(
                      externalAddress: externalAddress,
                      leading: GestureDetector(
                        onTap: () {
                          showSimpleBottomSheet<void>(
                            context: context,
                            child: TradeCommunityTokenDialog(externalAddress: externalAddress),
                          );
                        },
                        onDoubleTap: () {
                          TokenizedCommunityRoute(externalAddress: externalAddress)
                              .push<void>(context);
                        },
                        child: BuyButton(externalAddress: externalAddress),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    return info;
  }
}
