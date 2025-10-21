import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/follow_counters/follow_counters.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class PumpIonBuy extends HookConsumerWidget {
  const PumpIonBuy({
    required this.masterPubkey,
    super.key,
  });

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(masterPubkey));
    final avatarUrl = userMetadata.valueOrNull?.data.avatarUrl;

    final avatarColors = useAvatarColors(avatarUrl);

    const followCountersHeight = 57.0;
    const buyButtonHeight = 23.0;

    final gradient = useMemoized(
      () {
        return storyBorderGradients[Random().nextInt(storyBorderGradients.length)];
      },
      [avatarUrl],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0.s),
        child: ProfileBackground(
          color1: avatarColors.$1,
          color2: avatarColors.$2,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0.s, horizontal: 16.0.s),
            child: Column(
              children: [
                Container(
                  width: 94.0.s,
                  height: 94.0.s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0.s),
                    border: GradientBoxBorder(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient.colors,
                        stops: gradient.stops,
                      ),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Avatar(
                      size: 80.s,
                      imageUrl: avatarUrl,
                      borderRadius: BorderRadius.circular(18.0.s),
                    ),
                  ),
                ),
                SizedBox(height: 4.0.s),
                UserNameTile(
                  pubkey: masterPubkey,
                  profileMode: ProfileMode.dark,
                ),
                SizedBox(height: 16.0.s),
                SizedBox(
                  height: followCountersHeight.s + buyButtonHeight.s / 2,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      FollowCounters(
                        pubkey: masterPubkey,
                        profileMode: ProfileMode.dark,
                        height: followCountersHeight,
                      ),
                      const Positioned(
                        bottom: 0,
                        child: BuyButton(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
