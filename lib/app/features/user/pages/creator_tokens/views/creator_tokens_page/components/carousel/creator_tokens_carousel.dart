// SPDX-License-Identifier: ice License 1.0

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorTokensCarousel extends HookConsumerWidget {
  const CreatorTokensCarousel({
    required this.items,
    required this.onItemChanged,
    super.key,
  });

  final List<String> items;
  final void Function(String) onItemChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CarouselSlider.builder(
      options: CarouselOptions(
        height: 304.0.s,
        viewportFraction: 0.75,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        enlargeStrategy: CenterPageEnlargeStrategy.zoom,
        onPageChanged: (index, _) => onItemChanged(items[index]),
      ),
      itemCount: items.length,
      itemBuilder: (context, index, realIndex) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.s),
          child: _CarouselCard(pubkey: items[index]),
        );
      },
    );
  }
}

class _CarouselCard extends HookConsumerWidget {
  const _CarouselCard({
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(pubkey));
    final avatarUrl = userMetadata.valueOrNull?.data.avatarUrl;
    final colors = useAvatarColors(avatarUrl);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0.s),
      ),
      clipBehavior: Clip.antiAlias,
      child: ProfileBackground(
        key: ValueKey(pubkey),
        colors: colors,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.0.s),
                color: context.theme.appColors.primaryBackground,
              ),
              padding: EdgeInsets.all(2.0.s),
              child: IonConnectAvatar(
                size: 98.0.s,
                masterPubkey: pubkey,
                borderRadius: BorderRadius.circular(20.0.s),
              ),
            ),
            SizedBox(height: 20.0.s),
            UserNameTile(
              pubkey: pubkey,
              profileMode: ProfileMode.dark,
              showProfileTokenPrice: true,
            ),
            SizedBox(height: 20.0.s),
            const _CreatorStatsWidget(
              //TODO: replace mock data
              amount: 43230430,
              transactions: 990,
              groups: 11320,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorStatsWidget extends StatelessWidget {
  const _CreatorStatsWidget({
    required this.amount,
    required this.transactions,
    required this.groups,
  });

  final int amount;
  final int transactions;
  final int groups;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.appColors.secondaryBackground;
    final iconColorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    final textStyle = context.theme.appTextThemes.caption2.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );

    final stats = [
      (icon: Assets.svg.iconMemeMarketcap, value: formatCount(amount)),
      (icon: Assets.svg.iconMemeMarkers, value: formatCount(transactions)),
      (icon: Assets.svg.iconSearchGroups, value: formatCount(groups)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 6.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in stats) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  item.icon,
                  colorFilter: iconColorFilter,
                  height: 12.0.s,
                  width: 12.0.s,
                ),
                SizedBox(height: 2.0.s),
                Text(item.value, style: textStyle),
              ],
            ),
            if (item != stats.last) SizedBox(width: 16.0.s),
          ],
        ],
      ),
    );
  }
}
