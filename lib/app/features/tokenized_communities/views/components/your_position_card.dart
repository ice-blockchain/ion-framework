// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/position_formatters.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_image.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

const _minDisplayUSD = 0.01;

class YourPositionCard extends HookConsumerWidget {
  const YourPositionCard({
    required this.token,
    this.trailing,
    this.onTap,
    super.key,
  });

  final CommunityToken token;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = token.marketData.position;

    // Only show card if user has an active position (not null and amount > 0)
    if (position == null) {
      return const SizedBox.shrink();
    }

    final avatarUrl = [
      token.imageUrl,
      token.creator.avatar,
    ].firstWhere((url) => url.isNotEmpty, orElse: () => '');

    final avatarColors = useImageColors(avatarUrl);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            margin: EdgeInsetsDirectional.fromSTEB(16.s, 12.s, 16.s, 12.s),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.s),
              child: ProfileBackground(
                colors: avatarColors,
                disableDarkGradient: true,
                child: Padding(
                  padding: EdgeInsetsDirectional.all(12.s),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CommunityTokenImage(
                          imageUrl: avatarUrl,
                          width: 52.s,
                          height: 52.s,
                          outerBorderRadius: 12.8.s,
                          innerBorderRadius: 9.6.s,
                          innerPadding: 2.s,
                        ),
                        SizedBox(width: 10.s),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _YourPositionCardTitle(),
                            SizedBox(height: 8.s),
                            _ProfitDetails(position: position),
                          ],
                        ),
                        const Spacer(),
                        _AmountDetails(position: position, avatarColors: avatarColors),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _YourPositionCardTitle extends StatelessWidget {
  const _YourPositionCardTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.i18n.your_position_card_title,
      style: context.theme.appTextThemes.subtitle3
          .copyWith(color: context.theme.appColors.secondaryBackground),
    );
  }
}

class _ProfitDetails extends StatelessWidget {
  const _ProfitDetails({
    required this.position,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    final profitColor = position.pnlPercentage >= 0
        ? context.theme.appColors.success
        : context.theme.appColors.raspberry;

    final displayPnl = position.pnl.abs() < _minDisplayUSD && position.pnl != 0
        ? _minDisplayUSD
        : position.pnl.abs();

    final pnlSign = getNumericSign(position.pnl);
    final pnlAmount = formatUSD(displayPnl);
    final percentageSign = getNumericSign(position.pnlPercentage);
    final percentageValue = position.pnlPercentage.abs().toStringAsFixed(2);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.s, vertical: 1.5.s),
      decoration: BoxDecoration(color: profitColor, borderRadius: BorderRadius.circular(6.s)),
      child: Row(
        children: [
          Assets.svg.iconChartLine.icon(
            size: 14.s,
            color: context.theme.appColors.onPrimaryAccent,
          ),
          SizedBox(width: 3.s),
          Text(
            '$pnlSign$pnlAmount ($percentageSign$percentageValue%)',
            style: context.theme.appTextThemes.body2.copyWith(
              color: context.theme.appColors.onPrimaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountDetails extends StatelessWidget {
  const _AmountDetails({
    required this.position,
    required this.avatarColors,
  });

  final Position position;
  final ({Color first, Color second})? avatarColors;

  @override
  Widget build(BuildContext context) {
    final displayAmountUSD = (position.amountUSD != null &&
            position.amountUSD != 0 &&
            position.amountUSD! < _minDisplayUSD)
        ? _minDisplayUSD
        : position.amountUSD;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Assets.svg.iconTabsCoins.icon(
              size: 16.s,
              color: context.theme.appColors.onPrimaryAccent,
            ),
            SizedBox(width: 3.s),
            Text(
              defaultAbbreviate(position.amountValue),
              style: context.theme.appTextThemes.body2
                  .copyWith(color: context.theme.appColors.onPrimaryAccent),
            ),
          ],
        ),
        SizedBox(height: 8.s),
        Row(
          children: [
            Assets.svg.iconCreatecoinDollar.icon(
              size: 16.s,
              color: context.theme.appColors.onPrimaryAccent,
            ),
            SizedBox(width: 1.s),
            if (displayAmountUSD == null)
              Text(
                formatUSD(displayAmountUSD!),
                style: context.theme.appTextThemes.body2
                    .copyWith(color: context.theme.appColors.onPrimaryAccent),
              )
            else
              ContainerSkeleton(
                width: 45.0.s,
                height: 20.0.s,
                skeletonBaseColor: avatarColors?.first.withValues(alpha: 10),
              ),
          ],
        ),
      ],
    );
  }
}
