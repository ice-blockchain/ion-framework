// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/hooks/use_check_wallet_address_available.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_receive_modal/components/coin_address_tile/coin_address_tile.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/receive_coins_form_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class CoinReceiveModal extends HookConsumerWidget {
  const CoinReceiveModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsGroup = ref.watch(
      receiveCoinsFormControllerProvider.select((state) => state.selectedCoin),
    )!;
    final selectedNetwork = ref.watch(
      receiveCoinsFormControllerProvider.select((state) => state.selectedNetwork),
    );
    final coinsWithNetworkOptions = ref.watch(
      syncedCoinsBySymbolGroupProvider(coinsGroup.symbolGroup),
    );

    useOnInit(
      () {
        if (selectedNetwork == null) {
          coinsWithNetworkOptions.maybeWhen(
            data: (options) {
              var coinInWallet = options.firstWhereOrNull(
                (coinInWallet) => coinInWallet.walletId != null,
              );
              coinInWallet ??= options.firstOrNull;

              if (coinInWallet != null) {
                ref
                    .read(receiveCoinsFormControllerProvider.notifier)
                    .setNetwork(coinInWallet.coin.network);
              }
            },
            orElse: () {},
          );
        }
      },
      [coinsWithNetworkOptions],
    );

    useCheckWalletAddressAvailable(
      ref,
      network: selectedNetwork,
      coinsGroup: coinsGroup,
      onAddressFound: (address) =>
          ref.read(receiveCoinsFormControllerProvider.notifier).setWalletAddress(address),
      onAddressMissing: () => AddressNotFoundRoute().replace(ref.context),
      keys: [selectedNetwork, coinsGroup],
    );

    final updateNetwork = useCallback(
      (NetworkData? network) {
        if (network != null) {
          ref.read(receiveCoinsFormControllerProvider.notifier).setNetwork(network);
        }
      },
      [],
    );

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.wallet_receive),
            actions: [
              NavigationCloseButton(
                onPressed: Navigator.of(context, rootNavigator: true).pop,
              ),
            ],
            showBackButton: false,
          ),
          ScreenSideOffset.small(
            child: const CoinAddressTile(),
          ),
          SizedBox(
            height: 15.0.s,
          ),
          if (selectedNetwork case final NetworkData network)
            ScreenSideOffset.small(
              child: ListItem(
                title: Text(context.i18n.wallet_network),
                subtitle: Text(network.displayName),
                switchTitleStyles: true,
                leading: NetworkIconWidget(
                  type: WalletItemIconType.big(),
                  imageUrl: network.image,
                ),
                trailing: Text(
                  context.i18n.wallet_change,
                  style: context.theme.appTextThemes.caption.copyWith(
                    color: context.theme.appColors.primaryAccent,
                  ),
                ),
                onTap: () async {
                  final result = await ChangeNetworkShareWalletRoute().push<NetworkData?>(context);
                  if (result != null) updateNetwork(result);
                },
              ),
            ),
        ],
      ),
    );
  }
}
