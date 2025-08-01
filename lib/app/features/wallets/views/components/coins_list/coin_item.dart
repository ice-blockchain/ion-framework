// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/coins/coin_icon.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/unseen_transaction_indicator.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class CoinsGroupItem extends HookConsumerWidget {
  const CoinsGroupItem({
    required this.coinsGroup,
    required this.onTap,
    this.showNewTransactionsIndicator = false,
    super.key,
  });

  final CoinsGroup coinsGroup;
  final VoidCallback onTap;
  final bool showNewTransactionsIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);

    return ListItem(
      key: Key(coinsGroup.symbolGroup),
      title: Text(coinsGroup.name),
      subtitle: Text(coinsGroup.abbreviation),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      leading: CoinIconWidget.big(coinsGroup.iconUrl),
      onTap: onTap,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              if (showNewTransactionsIndicator)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 4.0.s),
                  child: UnseenTransactionsIndicator(
                    coinIds: coinsGroup.coins.map((e) => e.coin.id).toList(),
                  ),
                ),
              Text(
                isBalanceVisible ? formatCrypto(coinsGroup.totalAmount) : '****',
                style: context.theme.appTextThemes.body
                    .copyWith(color: context.theme.appColors.primaryText),
              ),
            ],
          ),
          Text(
            isBalanceVisible ? formatToCurrency(coinsGroup.totalBalanceUSD) : '******',
            style: context.theme.appTextThemes.caption3
                .copyWith(color: context.theme.appColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class CoinsGroupItemPlaceholder extends StatelessWidget {
  const CoinsGroupItemPlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListItem(
      title: ContainerSkeleton(
        height: 16.0.s,
        width: 101.0.s,
        skeletonBaseColor: context.theme.appColors.onTertiaryFill,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6.0.s),
          ContainerSkeleton(
            height: 12.0.s,
            width: 55.0.s,
            skeletonBaseColor: context.theme.appColors.onTertiaryFill,
          ),
        ],
      ),
      leading: Assets.svg.walletemptyicon2.icon(size: 36.0.s),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ContainerSkeleton(
            height: 16.0.s,
            width: 40.0.s,
            skeletonBaseColor: context.theme.appColors.onTertiaryFill,
          ),
          SizedBox(height: 6.0.s),
          ContainerSkeleton(
            height: 12.0.s,
            width: 30.0.s,
            skeletonBaseColor: context.theme.appColors.onTertiaryFill,
          ),
        ],
      ),
    );
  }
}
