// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_holder_position_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/profit_loss_indicator.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_price_label.dart';
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
                                ? ProfitLossIndicator(position: position)
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
        TokenPriceLabel(
          text: '\$${MarketDataFormatter.formatCompactNumber(holder.position.amountUSD)}',
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
