// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/wallet_address_notifier_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion_identity_client/ion_identity.dart';

void useCheckWalletAddressAvailable(
  WidgetRef ref, {
  required NetworkData? network,
  required CoinsGroup? coinsGroup,
  VoidCallback? onAddressMissing,
  ValueChanged<String>? onAddressFound,
  List<Object?> keys = const [],
}) {
  useOnInit(
    () {
      checkWalletAddressAvailable(
        ref,
        network: network,
        coinsGroup: coinsGroup,
        onAddressMissing: onAddressMissing,
        onAddressFound: onAddressFound,
      );
    },
    keys,
  );
}

Future<void> checkWalletAddressAvailable(
  WidgetRef ref, {
  required NetworkData? network,
  required CoinsGroup? coinsGroup,
  VoidCallback? onAddressMissing,
  ValueChanged<String>? onAddressFound,
}) async {
  final address = await ref
      .read(walletAddressNotifierProvider.notifier)
      .loadWalletAddress(network: network, coinsGroup: coinsGroup);

  if (!ref.context.mounted) return;

  if (address != null && onAddressFound != null) {
    onAddressFound(address);
  } else if (address == null && network?.displayName == 'ION') {
    _createIonWallet(ref, network!, onAddressFound);
  } else if (address == null && network != null) {
    onAddressMissing?.call();
  }
}

void _createIonWallet(
  WidgetRef ref,
  NetworkData network,
  ValueChanged<String>? onAddressFound,
) {
  guardPasskeyDialog(
    ref.context,
    (child) {
      return RiverpodVerifyIdentityRequestBuilder(
        provider: walletAddressNotifierProvider,
        requestWithVerifyIdentity: (OnVerifyIdentity<Wallet> onVerifyIdentity) async {
          final address = await ref
              .read(
                walletAddressNotifierProvider.notifier,
              )
              .createWallet(
                onVerifyIdentity: onVerifyIdentity,
                network: network,
              );

          if (address != null && onAddressFound != null) {
            onAddressFound(address);
          }
        },
        child: child,
      );
    },
  );
}
