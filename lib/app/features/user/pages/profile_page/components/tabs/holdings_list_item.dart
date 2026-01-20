// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_holder_position_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_avatar.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class HoldingsListItem extends ConsumerWidget {
  const HoldingsListItem({
    required this.holder,
    required this.tokenExternalAddress,
    super.key,
  });

  final TopHolder holder;
  final String tokenExternalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holderAddress = holder.position.holder?.addresses?.ionConnect;
    final positionAsync = holderAddress != null
        ? ref.watch(
            tokenHolderPositionProvider(
              tokenExternalAddress,
              holderAddress,
            ),
          )
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  HolderAvatar(
                    imageUrl: holder.position.holder?.avatar,
                    seed: holder.position.holder?.name ??
                        holder.position.holder?.addresses?.ionConnect,
                  ),
                  if (holder.position.holder?.addresses?.twitter != null)
                    PositionedDirectional(
                      start: 23.0.s,
                      top: 20.0.s,
                      child: Assets.svg.iconLoginXlogo.icon(size: 12.0.s),
                    ),
                ],
              ),
              SizedBox(width: 8.0.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getDisplayName(context),
                      style: context.theme.appTextThemes.subtitle3.copyWith(
                        color: context.theme.appColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Assets.svg.iconTabsCoins.icon(
                          size: 14.15.s,
                          color: context.theme.appColors.quaternaryText,
                        ),
                        SizedBox(width: 4.0.s),
                        Text(
                          formatAmountCompactFromRaw(holder.position.amount),
                          style: context.theme.appTextThemes.caption.copyWith(
                            color: context.theme.appColors.quaternaryText,
                          ),
                        ),
                        SizedBox(width: 6.0.s),
                        Text(
                          '•',
                          style: context.theme.appTextThemes.caption.copyWith(
                            color: context.theme.appColors.quaternaryText,
                          ),
                        ),
                        SizedBox(width: 6.0.s),
                        if (positionAsync != null)
                          positionAsync.when(
                            data: (position) => position != null
                                ? _ProfitLossIndicator(position: position)
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
          decoration: BoxDecoration(
            color: context.theme.appColors.primaryAccent,
            borderRadius: BorderRadius.circular(12.0.s),
          ),
          child: Text(
            '\$${MarketDataFormatter.formatCompactNumber(holder.position.amountUSD)}',
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.onPrimaryAccent,
              height: 16 / context.theme.appTextThemes.caption2.fontSize!,
            ),
          ),
        ),
      ],
    );
  }

  String _getDisplayName(BuildContext context) {
    final holder = this.holder.position.holder;
    final displayName = holder?.display ?? holder?.name ?? '';
    final rank = this.holder.position.rank;
    return '$displayName #$rank';
  }
}

class _ProfitLossIndicator extends StatelessWidget {
  const _ProfitLossIndicator({
    required this.position,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    final isProfit = position.pnl >= 0;
    final profitColor = isProfit
        ? context.theme.appColors.success
        : context.theme.appColors.lossRed;

    final pnlSign = getNumericSign(position.pnl);
    final pnlAmount = MarketDataFormatter.formatCompactNumber(position.pnl.abs());

    return Row(
      children: [
        Assets.svg.iconCreatecoinProfit.icon(
          size: 14.15.s,
          color: profitColor,
        ),
        SizedBox(width: 4.0.s),
        Text(
          '$pnlSign\$$pnlAmount',
          style: context.theme.appTextThemes.caption.copyWith(
            color: profitColor,
          ),
        ),
      ],
    );
  }
}
