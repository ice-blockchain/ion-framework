// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';

final mainWalletForAccountProvider = FutureProvider.family<Wallet?, String>(
  (ref, identityKeyName) async {
    try {
      final ionIdentity = await ref.watch(ionIdentityProvider.future);
      final ionIdentityClient = ionIdentity(username: identityKeyName);
      final wallets = await ionIdentityClient.wallets.getWallets();
      return wallets.firstWhereOrNull((wallet) => wallet.name == 'main');
    } catch (_) {
      return null;
    }
  },
);
