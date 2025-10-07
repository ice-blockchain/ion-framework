// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometrics_provider.r.g.dart';

@riverpod
Future<BiometricsState?> userBiometricsState(
  Ref ref, {
  required String username,
}) async {
  final ionIdentity = await ref.watch(ionIdentityProvider.future);
  return ionIdentity(username: username).auth.getBiometricsState();
}

@Riverpod(keepAlive: true)
Stream<Map<String, BiometricsState>> biometricsStatesStream(Ref ref) async* {
  final ionIdentity = await ref.watch(ionIdentityProvider.future);

  yield* ionIdentity.biometricsStatesStream;
}

@riverpod
class RejectToUseBiometricsNotifier extends _$RejectToUseBiometricsNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> rejectToUseBiometrics({required String username, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _performPasswordDelegation(ref, password);
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      await ionIdentity(username: username).auth.rejectToUseBiometrics();
    });
  }
}

@riverpod
class EnrollToUseBiometricsNotifier extends _$EnrollToUseBiometricsNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> enrollToUseBiometrics({
    required String username,
    required String password,
    required String localisedReason,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _performPasswordDelegation(ref, password);
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      await ionIdentity(username: username).auth.enrollToUseBiometrics(
            password: password,
            localisedReason: localisedReason,
          );
    });
  }
}

Future<void> _performPasswordDelegation(Ref ref, String password) async {
  try {
    final userMetadata = await ref.read(currentUserMetadataProvider.future);
    if (userMetadata != null) {
      await ref.read(onboardingCompleteNotifierProvider.notifier).addDelegation(
            ({
              required onPasskeyFlow,
              required onPasswordFlow,
              required onBiometricsFlow,
            }) =>
                onPasswordFlow(password: password),
          );
    }
  } catch (error, stackTrace) {
    Logger.log(
      'Error during add delegation flow',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

@riverpod
BiometricsService biometricsService(Ref ref) {
  return const BiometricsService();
}
