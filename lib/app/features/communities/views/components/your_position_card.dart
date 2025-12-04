// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/communities/utils/position_formatters.dart';
import 'package:ion/app/features/communities/views/components/community_token_image.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class YourPositionCard extends HookConsumerWidget {
  const YourPositionCard({required this.externalAddress, this.trailing, super.key});

  final String externalAddress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;

    if (token == null) {
      return const SizedBox();
    }

    final position = token.marketData.position;

    if (position == null) {
      return const SizedBox();
    }

    final avatarColors = useImageColors(token.imageUrl);

    return Column(
      children: [
        Container(
          margin: EdgeInsetsDirectional.fromSTEB(16.s, 10.s, 16.s, 10.s),
          child: SizedBox(
            height: 72.s,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.s),
              child: ProfileBackground(
                colors: avatarColors,
                disableDarkGradient: true,
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12.s, 12.s, 14.s, 12.s),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CommunityTokenImage(
                          imageUrl: token.imageUrl,
                          size: 49.6.s,
                          outerBorderRadius: 12.8.s,
                          innerBorderRadius: 9.6.s,
                          innerPadding: 1.29.s,
                        ),
                        SizedBox(width: 10.s),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _YourPositionCardTitle(),
                            _ProfitDetails(position: position),
                          ],
                        ),
                        const Spacer(),
                        _AmountDetails(position: position),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
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
        ? context.theme.appColors.profitGreen
        : context.theme.appColors.lossRed;

    return Row(
      children: [
        Assets.svg.iconCreatecoinProfit.icon(
          size: 14.s,
          color: profitColor,
        ),
        SizedBox(width: 3.s),
        Text(
          '${getNumericSign(position.pnl)}${position.pnl.toStringAsFixed(2)} (${getNumericSign(position.pnlPercentage)}${position.pnlPercentage.toStringAsFixed(2)}%)',
          style: context.theme.appTextThemes.body2.copyWith(
            color: profitColor,
          ),
        ),
      ],
    );
  }
}

class _AmountDetails extends StatelessWidget {
  const _AmountDetails({
    required this.position,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Assets.svg.iconTabsCoins.icon(
              size: 16.s,
              color: context.theme.appColors.onPrimaryAccent,
            ),
            SizedBox(width: 3.s),
            Text(
              defaultAbbreviate(position.amount),
              style: context.theme.appTextThemes.body2
                  .copyWith(color: context.theme.appColors.onPrimaryAccent),
            ),
          ],
        ),
        Row(
          children: [
            Assets.svg.iconCreatecoinDollar.icon(
              size: 16.s,
              color: context.theme.appColors.onPrimaryAccent,
            ),
            SizedBox(width: 1.s),
            Text(
              formatUSD(position.amountUSD),
              style: context.theme.appTextThemes.body2
                  .copyWith(color: context.theme.appColors.onPrimaryAccent),
            ),
          ],
        ),
      ],
    );
  }
}
