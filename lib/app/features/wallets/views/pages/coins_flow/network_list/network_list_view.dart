// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/user/providers/request_coins_form_provider.r.dart';
import 'package:ion/app/features/wallets/hooks/use_check_wallet_address_available.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/selectable_networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/network_list/network_item.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/receive_coins_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/utils/network_validator.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

enum NetworkListViewType { send, receive, request, swapSell, swapBuy }

class NetworkListView extends HookConsumerWidget {
  const NetworkListView({
    this.type = NetworkListViewType.send,
    this.onSelectReturnType = false,
    this.sendFormRouteLocationBuilder,
    super.key,
  });

  final bool onSelectReturnType;
  final NetworkListViewType type;
  final String Function()? sendFormRouteLocationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsGroup = switch (type) {
      NetworkListViewType.send =>
        ref.watch(sendAssetFormControllerProvider).assetData.as<CoinAssetToSendData>()?.coinsGroup,
      NetworkListViewType.receive => ref.watch(receiveCoinsFormControllerProvider).selectedCoin!,
      NetworkListViewType.request => ref
          .watch(requestCoinsFormControllerProvider)
          .assetData
          .as<CoinAssetToSendData>()
          ?.coinsGroup,
      NetworkListViewType.swapSell => ref.watch(swapCoinsControllerProvider).sellCoin,
      NetworkListViewType.swapBuy => ref.watch(swapCoinsControllerProvider).buyCoin,
    };

    final contactPubkey = switch (type) {
      NetworkListViewType.send =>
        ref.watch(sendAssetFormControllerProvider.select((state) => state.contactPubkey)),
      NetworkListViewType.request =>
        ref.watch(requestCoinsFormControllerProvider.select((state) => state.contactPubkey)),
      _ => null,
    };

    final isProcessing = useRef(false);
    Future<void> onNetworkTap(NetworkData network) async {
      try {
        if (isProcessing.value) return;
        isProcessing.value = true;
        await _onTap(context, ref, network);
      } finally {
        isProcessing.value = false;
      }
    }

    final hasContact = contactPubkey?.isNotEmpty ?? false;
    final shouldDisableUnavailable = const {
          NetworkListViewType.send,
          NetworkListViewType.request,
        }.contains(type) &&
        hasContact;

    final child = shouldDisableUnavailable
        ? _SelectableNetworksList(
            coinsGroup: coinsGroup,
            contactPubkey: contactPubkey!,
            onNetworkTap: onNetworkTap,
          )
        : _UnrestrictedNetworksList(
            coinsGroup: coinsGroup,
            onNetworkTap: onNetworkTap,
          );

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.s),
            child: NavigationAppBar.screen(
              title: Text(context.i18n.wallet_choose_network),
              actions: const [
                NavigationCloseButton(),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: 32.0.s),
              child: ScreenSideOffset.small(
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    NetworkData network,
  ) async {
    if (onSelectReturnType) {
      Navigator.of(context).pop(network);
      return;
    }

    switch (type) {
      case NetworkListViewType.send:
        final state = ref.read(sendAssetFormControllerProvider);
        final isNetworkValid = await checkWalletExists(ref, state.contactPubkey, network);

        if (!isNetworkValid) {
          return;
        }

        if (context.mounted) {
          unawaited(ref.read(sendAssetFormControllerProvider.notifier).setNetwork(network));
          unawaited(context.push<void>(sendFormRouteLocationBuilder!()));
        }
      case NetworkListViewType.receive:
        final coin = ref.read(receiveCoinsFormControllerProvider).selectedCoin;
        ref.read(receiveCoinsFormControllerProvider.notifier).setNetwork(network);
        unawaited(
          checkWalletAddressAvailable(
            ref,
            network: network,
            coinsGroup: coin,
            onAddressMissing: () => AddressNotFoundReceiveCoinsRoute().push<void>(ref.context),
            onAddressFound: (_) => ShareAddressToGetCoinsRoute().push<void>(context),
          ),
        );
      case NetworkListViewType.request:
        final form = ref.read(requestCoinsFormControllerProvider);
        final isNetworkValid = await checkWalletExists(ref, form.contactPubkey, network);

        if (!isNetworkValid) {
          return;
        }

        if (context.mounted) {
          unawaited(ref.read(requestCoinsFormControllerProvider.notifier).setNetwork(network));
          unawaited(context.push(sendFormRouteLocationBuilder!()));
        }
      case NetworkListViewType.swapSell:
        ref.read(swapCoinsControllerProvider.notifier).setSellNetwork(network);
        context.pop();
      case NetworkListViewType.swapBuy:
        ref.read(swapCoinsControllerProvider.notifier).setBuyNetwork(network);
        context.pop();
    }
  }
}

class _UnrestrictedNetworksList extends ConsumerWidget {
  const _UnrestrictedNetworksList({
    required this.coinsGroup,
    required this.onNetworkTap,
  });

  final CoinsGroup? coinsGroup;
  final Future<void> Function(NetworkData network) onNetworkTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsState = coinsGroup == null
        ? const AsyncValue<List<CoinInWalletData>>.loading()
        : ref.watch(syncedCoinsBySymbolGroupProvider(coinsGroup!.symbolGroup));

    if (!coinsState.hasValue) {
      return _LoadingState(itemCount: coinsGroup?.coins.length ?? 1);
    }

    return _NetworksList(
      itemCount: coinsState.value!.length,
      itemBuilder: (BuildContext context, int index) {
        final coin = coinsState.value![index];
        final network = coin.coin.network;
        return NetworkItem(
          coinInWallet: coin,
          network: network,
          onTap: () => onNetworkTap(network),
        );
      },
    );
  }
}

class _SelectableNetworksList extends ConsumerWidget {
  const _SelectableNetworksList({
    required this.coinsGroup,
    required this.onNetworkTap,
    required this.contactPubkey,
  });

  final CoinsGroup? coinsGroup;
  final Future<void> Function(NetworkData network) onNetworkTap;
  final String contactPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networksState = coinsGroup == null
        ? const AsyncValue<SelectableNetworkState>.loading()
        : ref.watch(
            selectableNetworksProvider(
              symbolGroup: coinsGroup!.symbolGroup,
              contactPubkey: contactPubkey,
            ),
          );

    if (!networksState.hasValue) {
      return _LoadingState(itemCount: coinsGroup?.coins.length ?? 1);
    }

    final enabledNetworkIds = networksState.value!.enabledNetworkIds;

    return _NetworksList(
      itemCount: networksState.value!.coins.length,
      itemBuilder: (BuildContext context, int index) {
        final coin = networksState.value!.coins[index];
        final network = coin.coin.network;
        final isEnabled = enabledNetworkIds.contains(network.id);
        final networkItem = NetworkItem(
          coinInWallet: coin,
          network: network,
          onTap: () => onNetworkTap(network),
        );

        if (isEnabled) {
          return networkItem;
        }

        return IgnorePointer(
          child: Opacity(
            opacity: 0.3,
            child: networkItem,
          ),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const mockedNetwork = NetworkData(
      id: '',
      image: '',
      isTestnet: false,
      displayName: '',
      explorerUrl: '',
      tier: 0,
    );

    const mockedCoin = CoinInWalletData(
      coin: CoinData(
        id: '',
        contractAddress: '',
        decimals: 1,
        iconUrl: '',
        name: '',
        network: mockedNetwork,
        priceUSD: 1,
        abbreviation: '',
        symbolGroup: '',
        syncFrequency: Duration.zero,
      ),
    );

    return Skeleton(
      child: _NetworksList(
        itemCount: itemCount,
        itemBuilder: (_, __) {
          return NetworkItem(
            coinInWallet: mockedCoin,
            network: mockedNetwork,
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _NetworksList extends StatelessWidget {
  const _NetworksList({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 12.0.s),
      itemBuilder: itemBuilder,
    );
  }
}
