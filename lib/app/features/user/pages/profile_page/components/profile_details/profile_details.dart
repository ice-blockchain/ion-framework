// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/extensions/user_metadata.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/follow_counters/follow_counters.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_actions/edit_user_button.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_actions/profile_actions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_user_info.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_watch_when_visible.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class ProfileDetails extends HookConsumerWidget {
  const ProfileDetails({
    required this.pubkey,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(pubkey));

    final eventReference = userMetadata.valueOrNull?.toEventReference();

    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));

    final hasBscWallet = (userMetadata.valueOrNull?.hasBscWallet).falseOrValue;

    // Always call hook unconditionally (required by Flutter hooks rules)
    // The watcher handles conditional logic internally
    final tokenInfo = useWatchWhenVisible<AsyncValue<CommunityToken?>>(
      watcher: () {
        if (profileMode == ProfileMode.dark && eventReference != null && hasBscWallet) {
          return ref.watch(
            tokenMarketInfoIfAvailableProvider(eventReference),
          );
        }
        return const AsyncData<CommunityToken?>(null);
      },
    );
    final token = tokenInfo.valueOrNull;

    return ScreenSideOffset.small(
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (eventReference != null && token != null) {
                TokenizedCommunityRoute(
                  externalAddress: token.externalAddress,
                ).push<void>(context);
              }
            },
            child: UserNameTile(
              pubkey: pubkey,
              profileMode: profileMode,
              showProfileTokenPrice: profileMode == ProfileMode.dark,
              priceUsd: token?.marketData.priceUSD,
            ),
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
            pubkey: pubkey,
            profileMode: profileMode,
            hasBscWallet: hasBscWallet,
          ),
        ],
      ),
    );
  }
}
