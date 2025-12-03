// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/communities/extensions/replaceable_entity.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/follow_counters/follow_counters.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_actions/edit_user_button.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_actions/profile_actions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_user_info.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

class ProfileDetails extends ConsumerWidget {
  const ProfileDetails({
    required this.pubkey,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));
    final userMetadata = ref.watch(userMetadataProvider(pubkey));

    final tokenInfo = profileMode == ProfileMode.dark
        ? ref.watch(tokenMarketInfoProvider(userMetadata.valueOrNull!.externalAddress))
        : null;
    final token = tokenInfo?.valueOrNull;

    return ScreenSideOffset.small(
      child: Column(
        children: [
          UserNameTile(
            pubkey: pubkey,
            profileMode: profileMode,
            showProfileTokenPrice: profileMode == ProfileMode.dark,
            priceUsd: token?.marketData.priceUSD,
          ),
          SizedBox(height: 12.0.s),
          if (profileMode != ProfileMode.dark)
            isCurrentUserProfile
                ? const EditUserButton()
                : ProfileActions(pubkey: pubkey, profileMode: profileMode),
          if (profileMode != ProfileMode.dark) SizedBox(height: 16.0.s),
          FollowCounters(pubkey: pubkey, profileMode: profileMode),
          SizedBox(height: profileMode != ProfileMode.dark ? 12.0.s : 22.0.s),
          ProfileUserInfo(
            externalAddress: userMetadata.valueOrNull?.externalAddress,
            pubkey: pubkey,
            profileMode: profileMode,
          ),
        ],
      ),
    );
  }
}
