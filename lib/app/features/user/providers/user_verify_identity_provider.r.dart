// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/model/verify_identity_type.dart';
import 'package:ion/app/features/user/providers/biometrics_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_verify_identity_provider.r.g.dart';

// It is without code generation here cause code generation for providers can't handle generics
AutoDisposeFutureProvider<T> verifyUserIdentityProvider<T>({
  required Future<T> Function(OnPasswordFlow<T> onPasswordFlow) onGetPassword,
  required OnPasswordFlow<T> onPasswordFlow,
  required OnPasskeyFlow<T> onPasskeyFlow,
  required OnBiometricsFlow<T> onBiometricsFlow,
  required String localisedReasonForBiometricsDialog,
  required String localisedCancelForBiometricsDialog,
  String? identityKeyName,
}) {
  return FutureProvider.autoDispose<T>((ref) async {
    final username = identityKeyName ?? ref.read(currentIdentityKeyNameSelectorProvider)!;
    final ionIdentity = await ref.read(ionIdentityProvider.future);
    final isPasswordFlowUser = ionIdentity(username: username).auth.isPasswordFlowUser();
    final biometricsState = ionIdentity(username: username).auth.getBiometricsState();

    if (isPasswordFlowUser) {
      if (biometricsState == BiometricsState.enabled) {
        try {
          return await onBiometricsFlow(
            localisedReason: localisedReasonForBiometricsDialog,
            localisedCancel: localisedCancelForBiometricsDialog,
          );
          // If biometrics flow fails then fallback to password flow
        } catch (_) {}
      }
      return onGetPassword(onPasswordFlow);
    } else {
      return onPasskeyFlow();
    }
  });
}

@riverpod
Future<VerifyIdentityType> verifyIdentityType(
  Ref ref, {
  String? identityKeyName,
}) async {
  final username = identityKeyName ?? ref.watch(currentIdentityKeyNameSelectorProvider);
  final ionIdentity = await ref.read(ionIdentityProvider.future);

  if (username != null) {
    if (ionIdentity(username: username).auth.isPasswordFlowUser()) {
      final userBiometricsState =
          await ref.read(userBiometricsStateProvider(username: username).future);
      return userBiometricsState == BiometricsState.enabled
          ? VerifyIdentityType.biometrics
          : VerifyIdentityType.password;
    }
    return VerifyIdentityType.passkey;
  }

  final isPasskeyAvailable = await ref.read(isPasskeyAvailableProvider.future);
  return isPasskeyAvailable ? VerifyIdentityType.passkey : VerifyIdentityType.password;
}

@riverpod
Future<bool> isPasswordFlowUser(Ref ref) async {
  final username = ref.watch(currentIdentityKeyNameSelectorProvider);
  final ionIdentity = await ref.watch(ionIdentityProvider.future);
  return ionIdentity(username: username ?? '').auth.isPasswordFlowUser();
}

@riverpod
Future<bool> isPasskeyAvailable(Ref ref) async {
  try {
    final ionIdentity = await ref.read(ionIdentityProvider.future);
    return ionIdentity(username: '').auth.isPasskeyAvailable();
  } catch (error, stackTrace) {
    // intentionally ignore exceptions
    Logger.log('Passkey check exception', error: error, stackTrace: stackTrace);
    return false;
  }
}
