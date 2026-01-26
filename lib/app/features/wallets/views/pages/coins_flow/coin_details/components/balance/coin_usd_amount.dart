// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/string.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/model/balance_display_order.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/wallet_user_preferences_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/balance_provider.r.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class CoinUsdAmount extends HookConsumerWidget {
  const CoinUsdAmount({
    required this.coinsGroup,
    super.key,
  });

  final CoinsGroup coinsGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayOrder = ref.watch(balanceDisplayOrderProvider);
    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);
    final balance = ref.watch(coinBalanceNotifierProvider(symbolGroup: coinsGroup.symbolGroup));

    final coinText = isBalanceVisible
        ? '${formatCrypto(balance.amount)} ${coinsGroup.abbreviation}'
        : StringConstants.obfuscated;
    final usdText = isBalanceVisible
        ? context.i18n.wallet_approximate_in_usd(
            formatUSD(balance.balanceUSD),
          )
        : StringConstants.obfuscated;

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider) ?? '';
            ref
                .read(
                  walletUserPreferencesNotifierProvider(identityKeyName: identityKeyName).notifier,
                )
                .switchBalanceDisplayOrder();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayOrder == BalanceDisplayOrder.coinUsd ? coinText : usdText,
                  style: context.theme.appTextThemes.headline1.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(
                width: 4.0.s,
              ),
              Assets.svg.iconArrowSelect.icon(size: 12.0.s),
            ],
          ),
        ),
        Text(
          displayOrder == BalanceDisplayOrder.coinUsd ? usdText : coinText,
          style: context.theme.appTextThemes.subtitle2.copyWith(
            color: context.theme.appColors.onTertiaryBackground,
          ),
        ),
      ],
    );
  }
}
