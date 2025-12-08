// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_public_wallets_sync_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<void> userPublicWalletsSync(Ref ref) async {
  final authState = await ref.watch(authProvider.future);

  if (!authState.isAuthenticated) {
    return;
  }

  final userMetadata = await ref.watch(currentUserMetadataProvider.future);
  final delegationComplete = await ref.watch(delegationCompleteProvider.future);

  // Make sure, that crypto wallets loaded
  await ref.watch(mainCryptoWalletsProvider.future);

  final walletsUpdater = ref.watch(updateUserMetadataNotifierProvider.notifier);

  if (userMetadata == null || !delegationComplete) {
    return;
  }

  // Always publish wallets (wallet privacy feature removed)
  await walletsUpdater.publishWallets(WalletAddressPrivacyOption.public);
}
