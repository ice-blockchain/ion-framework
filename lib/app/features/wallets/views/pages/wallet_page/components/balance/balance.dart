// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/constants/string.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/balance/balance_actions.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/balance/balance_visibility_action.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_page_loader_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/num.dart';

class Balance extends ConsumerWidget {
  const Balance({required this.tab, super.key});

  final WalletTabType tab;

  static double get height => 154.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPageLoading = ref.watch(walletPageLoaderNotifierProvider);

    final currentWallet =
        ref.watch(currentWalletViewDataProvider.select((state) => state.valueOrNull));
    final walletBalance = currentWallet?.usdBalance;

    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);
    final hitSlop = 5.0.s;

    final shouldShowLoader = isPageLoading || walletBalance == null;

    return ScreenSideOffset.small(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: 6.0.s - hitSlop,
              bottom: 8.0.s - hitSlop,
            ),
            child: BalanceVisibilityAction(hitSlop: hitSlop, isLoading: shouldShowLoader),
          ),
          if (shouldShowLoader)
            ContainerSkeleton(
              width: 124.0.s,
              height: 30.0.s,
              margin: EdgeInsets.symmetric(vertical: 5.0.s),
            )
          else
            Text(
              isBalanceVisible ? formatToCurrency(walletBalance) : StringConstants.obfuscated,
              style: context.theme.appTextThemes.headline1
                  .copyWith(color: context.theme.appColors.primaryText),
            ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: 6.0.s,
            ),
            child: BalanceActions(
              isLoading: shouldShowLoader,
              onReceive: () {
                switch (tab) {
                  case WalletTabType.nfts:
                    SelectNetworkToReceiveNftRoute().push<void>(ref.context);
                  case WalletTabType.coins:
                    ReceiveCoinRoute().push<void>(context);
                }
              },
              onBuy: () => ComingSoonModalRoute().push<void>(context),
              onSwap: () => ComingSoonModalRoute().push<void>(context),
              onMore: () => WalletMainModalRoute().push<void>(context),
              onNeedToEnable2FA: () => SecureAccountModalRoute().push<void>(context),
            ),
          ),
        ],
      ),
    );
  }
}
