// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_recovery_key_action_notifier.r.g.dart';

@riverpod
class CreateRecoveryKeyActionNotifier extends _$CreateRecoveryKeyActionNotifier {
  @override
  FutureOr<RecoveryCredentials?> build() {
    return null;
  }

  Future<void> createRecoveryCredentials(
    OnVerifyIdentity<CredentialResponse> onVerifyIdentity,
  ) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final selectedUser = ref.read(currentIdentityKeyNameSelectorProvider);
      if (selectedUser == null) {
        throw Exception('No selected user');
      }

      final ionIdentity = await ref.read(ionIdentityProvider.future);
      try {
        final response = await ionIdentity(username: selectedUser)
            .auth
            .createRecoveryCredentials(onVerifyIdentity);
        return response;
      } on PasskeyCancelledException {
        return null;
      }
    });
  }
}
