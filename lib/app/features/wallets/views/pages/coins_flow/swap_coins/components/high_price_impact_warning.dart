// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class HighPriceImpactWarning extends StatelessWidget {
  const HighPriceImpactWarning({
    required this.priceImpact,
    super.key,
  });

  final double priceImpact;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final formattedImpact = '${priceImpact.toStringAsFixed(2)}%';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0.s),
      padding: EdgeInsets.symmetric(
        vertical: 8.s,
        horizontal: 10.s,
      ),
      decoration: BoxDecoration(
        color: colors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Assets.svg.subtract.icon(
                size: 15.s,
                color: colors.attentionRed,
              ),
              SizedBox(width: 8.s),
              Expanded(
                child: Text(
                  context.i18n.wallet_swap_confirmation_high_price_impact_title,
                  style: textStyles.caption2.copyWith(
                    color: colors.attentionRed,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.s),
          Text.rich(
            TextSpan(
              style: textStyles.caption2.copyWith(color: colors.primaryText),
              children: [
                TextSpan(
                  text: context.i18n.wallet_swap_confirmation_high_price_impact_description_prefix,
                ),
                TextSpan(
                  text: formattedImpact,
                  style: textStyles.caption2.copyWith(color: colors.attentionRed),
                ),
                TextSpan(
                  text: context.i18n.wallet_swap_confirmation_high_price_impact_description_suffix,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
