// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/auth/providers/relays_assigned_provider.r.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_complete_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<bool?> onboardingComplete(Ref ref) async {
  final mainWallet = await ref.watch(mainWalletProvider.future);
  final userIsReady = mainWallet?.signingKey.publicKey != null;
  if (!userIsReady) {
    return null;
  }

  final (relaysAssigned, delegationComplete, userMetadata) = await (
    ref.watch(relaysAssignedProvider.future),
    ref.watch(delegationCompleteProvider.future),
    ref.watch(currentUserMetadataProvider.future),
  ).wait;

  return delegationComplete.falseOrValue && relaysAssigned.falseOrValue && userMetadata != null;
}
