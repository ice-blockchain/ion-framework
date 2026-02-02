// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/signer/dtos/dtos.dart';
import 'package:ion_identity_client/src/signer/passkey_signer.dart';
import 'package:ion_identity_client/src/signer/password_signer.dart';

class IdentitySigner {
  IdentitySigner({
    required this.passkeySigner,
    required this.passwordSigner,
  });

  final PasskeysSigner passkeySigner;
  final PasswordSigner passwordSigner;

  Future<CredentialRequestData> registerWithPasskey(UserRegistrationChallenge challenge) async {
    return passkeySigner.register(challenge);
  }

  Future<CredentialRequestData> registerWithPassword({
    required String challenge,
    required String password,
    required String username,
    required CredentialKind credentialKind,
  }) async {
    return passwordSigner.createCredentialInfo(
      challenge: challenge,
      password: password,
      username: username,
      credentialKind: credentialKind,
    );
  }

  Future<AssertionRequestData> loginWithPasskey({
    required String username,
    required UserActionChallenge challenge,
    required bool localCredsOnly,
  }) async {
    return passkeySigner.login(
      challenge: challenge,
      username: username,
      localCredsOnly: localCredsOnly,
    );
  }

  Future<AssertionRequestData> signWithPasskey(UserActionChallenge challenge) async {
    return passkeySigner.sign(challenge);
  }

  Future<AssertionRequestData> signWithPassword({
    required String challenge,
    required String encryptedPrivateKey,
    required String password,
    required String credentialId,
    required CredentialKind credentialKind,
  }) async {
    return passwordSigner.signWithPassword(
      challenge: challenge,
      encryptedPrivateKey: encryptedPrivateKey,
      password: password,
      credentialKind: credentialKind,
      credentialId: credentialId,
    );
  }

  Future<AssertionRequestData> signWithBiometrics({
    required String username,
    required String localisedReason,
    required String localisedCancel,
    required String encryptedPrivateKey,
    required String challenge,
    required String credentialId,
    required CredentialKind credentialKind,
  }) async {
    return passwordSigner.signWithBiometrics(
      username: username,
      encryptedPrivateKey: encryptedPrivateKey,
      localisedReason: localisedReason,
      challenge: challenge,
      credentialKind: credentialKind,
      credentialId: credentialId,
      localisedCancel: localisedCancel,
    );
  }

  Future<bool> isPasskeyAvailable() {
    return passkeySigner.checkPasskeyAvailability();
  }

  Future<void> cancelCurrentAuthenticatorOperation() {
    return passkeySigner.cancelCurrentAuthenticatorOperation();
  }

  Future<void> rejectToUseBiometrics(String username) {
    return passwordSigner.rejectToUseBiometrics(username);
  }

  Future<void> rejectToCreateLocalPasskeyCreds(String username) {
    return passkeySigner.rejectToCreateLocalPasskeyCreds(username);
  }

  Future<void> enrollToUseBiometrics({
    required String username,
    required String password,
    required String localisedReason,
  }) {
    return passwordSigner.enrollToUseBiometrics(
      username: username,
      password: password,
      localisedReason: localisedReason,
    );
  }

  PublicKeyCredentialDescriptor extractPasswordProtectedCredentials(
    UserActionChallenge challenge,
  ) {
    final credentialDescriptor = challenge.allowCredentials.passwordProtectedKey?.firstOrNull;
    // If no password-protected credential is available, throw an exception.
    if (credentialDescriptor == null || credentialDescriptor.encryptedPrivateKey == null) {
      throw const PasswordFlowNotAvailableForTheUserException();
    }

    return credentialDescriptor;
  }
}
