// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/user/user_about/user_about.dart';
import 'package:ion/app/features/components/user/user_info_summary/user_info_summary.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/relevant_followers/relevant_followers.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ProfileUserInfo extends ConsumerWidget {
  const ProfileUserInfo({
    required this.pubkey,
    required this.profileMode,
    required this.hasBscWallet,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;
  final bool hasBscWallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));

    final eventReference = ref.watch(userMetadataProvider(pubkey)).valueOrNull?.toEventReference();
    final eventReferenceString = eventReference?.toString();

    final info = Column(
      children: [
        if (!isCurrentUserProfile)
          RelevantFollowers(
            pubkey: pubkey,
            profileMode: profileMode,
          ),
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
            if (hasBscWallet && eventReferenceString != null)
              Column(
                children: [
                  GradientHorizontalDivider(
                    margin: EdgeInsetsDirectional.symmetric(vertical: 12.5.s),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ProfileTokenStats(
                          externalAddress: eventReferenceString,
                          leading: GestureDetector(
                            onTap: () {
                              if (eventReference == null) return;
                              TokenizedCommunityRoute(
                                eventReference: eventReference.encode(),
                              ).push<void>(context);
                            },
                            child: const BuyButton(),
                          ),
                        ),
                      ),
                    ],
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
