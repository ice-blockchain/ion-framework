// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/constants/string.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';

class NetworkItem extends ConsumerWidget {
  const NetworkItem({
    required this.network,
    required this.coinInWallet,
    required this.onTap,
    this.isEnabled = true,
    super.key,
  });

  final NetworkData network;
  final VoidCallback onTap;
  final CoinInWalletData coinInWallet;
  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);

    return Opacity(
      opacity: isEnabled ? 1 : 0.3,
      child: ListItem(
        title: Row(
          children: [
            Expanded(
              child: Text(
                coinInWallet.coin.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 5.0.s),
            _NetworkLabel(network: network),
          ],
        ),
        subtitle: Text(coinInWallet.coin.abbreviation),
        backgroundColor: context.theme.appColors.tertiaryBackground,
        leading: CoinIconWithNetwork.small(
          coinInWallet.coin.iconUrl,
          network: network,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isBalanceVisible ? formatCrypto(coinInWallet.amount) : StringConstants.obfuscated,
              style: context.theme.appTextThemes.body
                  .copyWith(color: context.theme.appColors.primaryText),
            ),
            Text(
              isBalanceVisible
                  ? formatToCurrency(coinInWallet.balanceUSD)
                  : StringConstants.obfuscated,
              style: context.theme.appTextThemes.caption3
                  .copyWith(color: context.theme.appColors.secondaryText),
            ),
          ],
        ),
        onTap: isEnabled ? onTap : null,
      ),
    );
  }
}

class _NetworkLabel extends StatelessWidget {
  const _NetworkLabel({required this.network});

  final NetworkData network;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.s, horizontal: 6.s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.s),
        color: context.theme.appColors.attentionBlock,
      ),
      child: Text(
        network.displayName,
        style: context.theme.appTextThemes.caption3.copyWith(
          color: context.theme.appColors.quaternaryText,
        ),
        textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
        textAlign: TextAlign.center,
      ),
    );
  }
}
