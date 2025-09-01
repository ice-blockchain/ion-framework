// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/early_access_provider.r.dart';
import 'package:ion/app/services/device_identification/device_identification_service.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_action_notifier.r.g.dart';

@riverpod
class RegisterActionNotifier extends _$RegisterActionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> signUp({required String keyName}) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      final earlyAccessEmail = ref.read(earlyAccessEmailProvider);
      try {
        final deviceIdentificationServiceProviderNotifier =
            ref.read(deviceIdentificationServiceProvider.notifier);
        await ionIdentity(username: keyName).auth.registerUser(
              (username) async =>
                  deviceIdentificationServiceProviderNotifier.getRequestIdFor(username),
              earlyAccessEmail,
            );
      } on PasskeyCancelledException {
        return;
      }
    });
  }

  Future<void> signUpWithPassword({required String keyName, required String password}) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      final earlyAccessEmail = ref.read(earlyAccessEmailProvider);
      final deviceIdentificationServiceProviderNotifier =
          ref.read(deviceIdentificationServiceProvider.notifier);
      await ionIdentity(username: keyName).auth.registerUserWithPassword(
            password,
            (username) async =>
                deviceIdentificationServiceProviderNotifier.getRequestIdFor(username),
            earlyAccessEmail,
          );
    });
  }
}
