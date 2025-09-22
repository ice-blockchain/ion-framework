// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_wallet_provider.r.g.dart';

@riverpod
Future<Wallet?> mainWallet(Ref ref) async {
  keepAliveWhenAuthenticated(ref);

  final userAvailable = ref.watch(currentIdentityKeyNameSelectorProvider) != null;
  if (!userAvailable) {
    return null;
  }

  final wallets = await ref.watch(walletsNotifierProvider.future);
  final mainWallet = wallets.firstWhereOrNull((wallet) => wallet.name == 'main');

  if (mainWallet == null) {
    throw MainWalletNotFoundException();
  }

  return mainWallet;
}
