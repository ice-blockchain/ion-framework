// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bsc_wallet_check_provider.m.freezed.dart';
part 'bsc_wallet_check_provider.m.g.dart';

@freezed
class BscWalletCheckResult with _$BscWalletCheckResult {
  const factory BscWalletCheckResult({
    required bool hasBscWallet,
    NetworkData? bscNetwork,
  }) = _BscWalletCheckResult;
}

@riverpod
Future<BscWalletCheckResult> bscWalletCheck(Ref ref) async {
  final networks = await ref.watch(networksStreamProvider.future);
  final mainCryptoWallets = await ref.watch(mainCryptoWalletsProvider.future);

  final bscNetwork = networks.firstWhereOrNull((n) => n.isBsc);

  if (bscNetwork == null) {
    return const BscWalletCheckResult(hasBscWallet: false);
  }

  final hasBscWallet = mainCryptoWallets.any((wallet) => wallet.network == bscNetwork.id);

  return BscWalletCheckResult(
    hasBscWallet: hasBscWallet,
    bscNetwork: bscNetwork,
  );
}
