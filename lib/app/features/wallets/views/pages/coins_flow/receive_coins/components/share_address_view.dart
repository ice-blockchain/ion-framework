// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/hooks/use_check_wallet_address_available.dart';
import 'package:ion/app/features/wallets/views/components/share_address/share_address_sheet_content.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/receive_coins_form_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ShareAddressToGetCoinsView extends HookConsumerWidget {
  const ShareAddressToGetCoinsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(receiveCoinsFormControllerProvider);

    if (form.address == null) {
      useCheckWalletAddressAvailable(
        ref,
        network: form.selectedNetwork,
        coinsGroup: form.selectedCoin,
        onAddressFound: (address) {
          ref.read(receiveCoinsFormControllerProvider.notifier).setWalletAddress(address);
        },
        onAddressMissing: () => AddressNotFoundReceiveCoinsRoute().replace(ref.context),
        keys: [form.selectedNetwork, form.selectedCoin],
      );
    }

    return ShareAddressSheetContent(
      coin: form.selectedCoin,
      network: form.selectedNetwork!,
      walletAddress: form.address,
    );
  }
}
