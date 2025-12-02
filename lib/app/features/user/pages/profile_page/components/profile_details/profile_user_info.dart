// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/user/user_about/user_about.dart';
import 'package:ion/app/features/components/user/user_info_summary/user_info_summary.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/relevant_followers/relevant_followers.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class ProfileUserInfo extends ConsumerWidget {
  const ProfileUserInfo({
    required this.pubkey,
    required this.profileMode,
    required this.creatorTokenMarketData,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;
  final MarketData? creatorTokenMarketData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));

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
            Container(
              margin: EdgeInsetsDirectional.symmetric(vertical: 12.5.s),
              height: 0.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x00ffffff), Color(0xffe1eaf8), Color(0x00ffffff)],
                ),
              ),
            ),
            ProfileTokenStats(masterPubkey: pubkey, data: creatorTokenMarketData),
          ],
        ),
      );
    }

    return info;
  }
}
