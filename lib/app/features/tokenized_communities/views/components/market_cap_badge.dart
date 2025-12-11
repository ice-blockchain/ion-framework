// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/generated/assets.gen.dart';

class MarketCapBadge extends StatelessWidget {
  const MarketCapBadge({
    required this.marketCap,
    super.key,
  });

  final double marketCap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.primaryBackground,
        borderRadius: BorderRadius.circular(6.0.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Assets.svg.iconMemeMarketcap.icon(
            size: 16.0.s,
            color: context.theme.appColors.onTertiaryBackground,
          ),
          SizedBox(width: 4.0.s),
          Text(
            '\$${MarketDataFormatter.formatCompactNumber(marketCap)}',
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.onTertiaryBackground,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

