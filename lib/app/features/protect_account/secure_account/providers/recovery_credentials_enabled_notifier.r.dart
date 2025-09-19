// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recovery_credentials_enabled_notifier.r.g.dart';

@Riverpod(keepAlive: true)
class RecoveryCredentialsEnabled extends _$RecoveryCredentialsEnabled {
  @override
  Future<bool> build() async {
    final selectedUser = ref.watch(currentIdentityKeyNameSelectorProvider);
    if (selectedUser == null) {
      return false;
    }

    final ionIdentity = ref.watch(ionIdentityProvider).valueOrNull;
    if (ionIdentity == null) {
      return false;
    }
    final credentials = await ionIdentity(username: selectedUser).auth.getCredentialsList();
    return credentials.any((credential) => credential.kind == CredentialKind.RecoveryKey.name);
  }

  void setEnabled() => state = const AsyncValue.data(true);
}
