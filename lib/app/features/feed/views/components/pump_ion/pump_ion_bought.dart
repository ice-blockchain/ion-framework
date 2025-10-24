// SPDX-License-Identifier: ice License 1.0

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
import 'package:ion/app/features/user/pages/profile_page/components/profile_balance.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_chart.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats_data.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_hodl.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/num.dart';

enum ProfileChartType {
  raising,
  falling,
}

class PumpIonBought extends HookConsumerWidget {
  const PumpIonBought({
    required this.masterPubkey,
    super.key,
  });

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(masterPubkey));
    final avatarUrl = userMetadata.valueOrNull?.data.avatarUrl;

    final avatarColors = useAvatarColors(avatarUrl);

    final gradient = useMemoized(
      () {
        return storyBorderGradients[Random().nextInt(storyBorderGradients.length)];
      },
      [avatarUrl],
    );

    final topContainerHeight = 52.0.s;
    final padding = 16.0.s;
    final badgeHeight = 32.0.s;

    const type = ProfileChartType.raising;
    final badgeColor = switch (type) {
      ProfileChartType.raising => const Color(0xFF35D487),
      ProfileChartType.falling => const Color(0xFFFD4E4E),
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              ProfileBalance(
                height: topContainerHeight,
                // TODO: replace mock with real data
                coins: 14320,
                amount: 22.84,
              ),
              SizedBox(height: padding),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0.s),
                child: ProfileBackground(
                  color1: avatarColors.$1,
                  color2: avatarColors.$2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0.s, horizontal: 16.0.s),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 62.0.s,
                              height: 62.0.s,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.0.s),
                                // GradientBoxBorder not accepting AlignmentDirectional
                                border: GradientBoxBorder(
                                  gradient: LinearGradient(
                                    // ignore: prefer_alignment_directional
                                    begin: Alignment.topLeft,
                                    // ignore: prefer_alignment_directional
                                    end: Alignment.bottomRight,
                                    colors: gradient.colors,
                                    stops: gradient.stops,
                                  ),
                                  width: 1.5.s,
                                ),
                              ),
                              child: Center(
                                child: Avatar(
                                  size: 54.s,
                                  imageUrl: avatarUrl,
                                  borderRadius: BorderRadius.circular(12.0.s),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.0.s),
                            Expanded(
                              child: UserNameTile(
                                pubkey: masterPubkey,
                                profileMode: ProfileMode.dark,
                                mainAxisAlignment: MainAxisAlignment.start,
                                isDecoratedNichname: true,
                              ),
                            ),
                            const ProfileChart(
                              amount: 874.52,
                              type: type,
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0.s),
                        ProfileTokenStatsInfo(
                          data: ProfileTokenStatsData.mock(),
                        ),
                        SizedBox(height: 10.0.s),
                        ProfileHODL(
                          // TODO: replace with actual HODL time
                          time: DateTime.now().subtract(
                            const Duration(hours: 1, minutes: 23),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          PositionedDirectional(
            top: topContainerHeight - (badgeHeight - padding) / 2,
            height: badgeHeight,
            child: Container(
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40.0.s),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 4.0.s),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.0.s),
                decoration: ShapeDecoration(
                  color: badgeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.0.s),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  // TODO: replace with real data
                  formatToCurrency(0.14),
                  style: context.theme.appTextThemes.caption2.copyWith(
                    color: context.theme.appColors.primaryBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
