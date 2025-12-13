// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
//TODO: Commented out for RC/production release - Buy, Sell functionality not ready yet
// import 'package:ion/app/features/core/model/feature_flags.dart';
// import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_main_modal/wallet_main_modal_list_item.dart';
import 'package:ion/app/hooks/use_on_receive_funds_flow.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/main_modal_item.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletMainModalPage extends HookConsumerWidget {
  const WalletMainModalPage({
    super.key,
    this.symbolGroup,
  });

  final String? symbolGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onReceiveFlow = useOnReceiveFundsFlow(
      onReceive: () => _onFlow(context, ref, WalletMainModalListItem.receive),
      onNeedToEnable2FA: () => context.pushReplacement(SecureAccountModalRoute().location),
      ref: ref,
    );

    return SheetContent(
      topPadding: 0.0.s,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Header(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const HorizontalSeparator(),
              itemCount: WalletMainModalListItem.values.length,
              itemBuilder: (BuildContext context, int index) {
                final type = WalletMainModalListItem.values[index];

                return MainModalItem(
                  item: type,
                  onTap: () {
                    if (type == WalletMainModalListItem.receive) {
                      onReceiveFlow();
                    } else {
                      _onFlow(context, ref, type);
                    }
                  },
                  index: index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onFlow(
    BuildContext context,
    WidgetRef ref,
    WalletMainModalListItem type,
  ) {
    ref.invalidate(sendAssetFormControllerProvider);

    final symbolGroup = this.symbolGroup;
    if (symbolGroup != null) {
      final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;
      final coinsGroup =
          walletView?.coinGroups.firstWhereOrNull((e) => e.symbolGroup == symbolGroup);
      if (coinsGroup != null) {
        ref.read(sendAssetFormControllerProvider.notifier).setCoin(coinsGroup, walletView);
      }
    }

    final skipSelectCoinRoute = symbolGroup != null;

    if (type == WalletMainModalListItem.swap) {
      // Initialize swap state and open swap flow
      ref.read(swapCoinsControllerProvider.notifier).initSellCoin(
            coin: null,
            network: null,
          );
      context.pushReplacement(SwapCoinsRoute().location);
      return;
    }

    context.pushReplacement(
      _getSubRouteLocation(type, skipSelectCoinRoute: skipSelectCoinRoute),
    );
  }

  String _getSubRouteLocation(WalletMainModalListItem type, {bool skipSelectCoinRoute = false}) {
    return switch (type) {
      WalletMainModalListItem.send => skipSelectCoinRoute
          ? SelectNetworkWalletRoute().location
          : SelectCoinWalletRoute().location,
      WalletMainModalListItem.receive => ReceiveCoinRoute().location,
      WalletMainModalListItem.swap => SwapCoinsRoute().location,
    };
  }
}

// ignore: unused_element
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //TODO: Commented out for RC/production release - Buy, Sell functionality not ready yet
    const showBuySellButtons =
        false; /*ref
        .read(featureFlagsProvider.notifier)
        .get(TokenizedCommunitiesFeatureFlag.tokenizedCommunitiesEnabled);*/

    if (!showBuySellButtons) {
      return NavigationAppBar.modal(
        title: Text(context.i18n.wallet_modal_title),
        showBackButton: false,
      );
    }

    // ignore: dead_code
    return Column(
      children: [
        SizedBox(height: 24.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0.s),
          child: Row(
            children: [
              Expanded(
                child: Button.compact(
                  leadingIconOffset: 4.s,
                  leadingIcon: Assets.svg.iconWalletBuy.icon(),
                  label: Text(context.i18n.wallet_buy),
                  // TODO: implement buy currency flow
                  onPressed: () {},
                ),
              ),
              SizedBox(width: 12.0.s),
              Expanded(
                child: Button.compact(
                  leadingIconOffset: 4.s,
                  leadingIcon: Assets.svg.iconMemeCoins.icon(),
                  label: Text(context.i18n.wallet_sell),
                  // TODO: implement sell currency flow
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.s),
        const HorizontalSeparator(),
        SizedBox(height: 8.s),
      ],
    );
  }
}
