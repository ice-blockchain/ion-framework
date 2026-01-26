// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/constants/string.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_status.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/transaction_list_item_leading_icon.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/num.dart';

class TransactionListItem extends ConsumerWidget {
  const TransactionListItem({
    required this.transactionData,
    required this.coinData,
    required this.onTap,
    super.key,
  });

  final CoinData coinData;
  final VoidCallback onTap;
  final CoinTransactionData transactionData;

  Color _getTextColor(BuildContext context) {
    if (transactionData.origin.status == TransactionStatus.failed) {
      return context.theme.appColors.primaryText;
    }
    return switch (transactionData.transactionType) {
      TransactionType.receive => context.theme.appColors.success,
      TransactionType.send => context.theme.appColors.primaryText,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);

    final amountText =
        isBalanceVisible ? formatCrypto(transactionData.coinAmount) : StringConstants.obfuscated;
    final usdText = isBalanceVisible
        ? context.i18n.wallet_approximate_in_usd(formatUSD(transactionData.usdAmount))
        : StringConstants.obfuscated;

    return ListItem(
      onTap: onTap,
      title: Text(
        transactionData.origin.swapStatus != null
            ? context.i18n.wallet_swap
            : transactionData.transactionType.getDisplayName(context),
      ),
      subtitle: Row(
        children: [
          NetworkIconWidget(
            type: WalletItemIconType.small(),
            imageUrl: transactionData.network.image,
          ),
          SizedBox(
            width: 4.0.s,
          ),
          Text(
            toTimeDisplayValue(transactionData.timestamp),
          ),
        ],
      ),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      leading: TransactionListItemLeadingIcon(
        type: transactionData.transactionType,
        status: transactionData.origin.swapStatus != null
            ? switch (transactionData.origin.swapStatus!) {
                SwapStatus.pending => TransactionStatus.broadcasted,
                SwapStatus.succeeded => TransactionStatus.confirmed,
                SwapStatus.failed => TransactionStatus.failed,
              }
            : transactionData.origin.status,
        isSwap: transactionData.origin.swapStatus != null,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${transactionData.transactionType.sign} $amountText ${coinData.abbreviation}',
            style: context.theme.appTextThemes.body.copyWith(
              color: _getTextColor(context),
            ),
          ),
          Text(
            usdText,
            style: context.theme.appTextThemes.caption3.copyWith(
              color: context.theme.appColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
