// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client_example/providers/ion_identity_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_action_notifier.r.g.dart';

@riverpod
class LoginActionNotifier extends _$LoginActionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String keyName}) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      final signer =
          ionIdentity(username: keyName).userActionSignerFactory.createPasskeySigner();
      await ionIdentity(username: keyName).auth.loginUserWithSigner(
        signer: signer,
        twoFATypes: const [],
        localCredsOnly: true,
      );
    });
  }
}
