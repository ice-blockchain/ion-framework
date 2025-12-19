// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
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

@riverpod
Future<String?> userPubkeyByIdentityKeyName(
  Ref ref,
  String identityKeyName,
) async {
  const cacheKeyPrefix = 'user_pubkey_';

  final sharedPrefs = await ref.read(sharedPreferencesFoundationProvider.future);
  final cacheKey = '$cacheKeyPrefix$identityKeyName';
  final cachedPubkey = await sharedPrefs.getString(cacheKey);

  if (cachedPubkey != null && cachedPubkey.isNotEmpty) {
    return cachedPubkey;
  }

  try {
    final ionIdentity = await ref.read(ionIdentityProvider.future);
    final wallets = await ionIdentity(username: identityKeyName).wallets.getWallets();
    final mainWallet = wallets.firstWhereOrNull((Wallet wallet) => wallet.name == 'main');

    if (mainWallet != null) {
      final userPubkey = mainWallet.signingKey.publicKey;
      await sharedPrefs.setString(cacheKey, userPubkey);
      return userPubkey;
    }
  } catch (error, stackTrace) {
    Logger.error(
      error,
      message: 'Failed to get user pubkey for identity key name: $identityKeyName',
      stackTrace: stackTrace,
    );
    return null;
  }

  return null;
}
