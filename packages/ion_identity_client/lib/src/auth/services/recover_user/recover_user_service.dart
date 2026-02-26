// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/key_service.dart';
import 'package:ion_identity_client/src/auth/services/recover_user/data_sources/recover_user_data_source.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

class RecoverUserService {
  RecoverUserService({
    required this.username,
    required this.dataSource,
    required this.config,
    required this.identitySigner,
    required this.keyService,
  });

  final String username;
  final RecoverUserDataSource dataSource;
  final IONIdentityConfig config;
  final IdentitySigner identitySigner;
  final KeyService keyService;

  Future<UserRegistrationChallenge> initRecovery({
    required String credentialId,
    required List<TwoFAType> twoFATypes,
  }) async {
    final userRegistrationChallenge = await dataSource.createDelegatedRecoveryChallenge(
      username: username,
      credentialId: credentialId,
      twoFATypes: twoFATypes,
    );
    return userRegistrationChallenge;
  }

  Future<void> completeRecovery({
    required UserRegistrationChallenge challenge,
    required String credentialId,
    required String recoveryKey,
  }) async {
    final attestation = await identitySigner.registerWithPasskey(challenge);
    await _sendRecoveryWithCredential(
      challenge: challenge,
      credentialId: credentialId,
      recoveryKey: recoveryKey,
      firstFactorCredential: attestation,
    );
  }

  /// Completes recovery by registering a new password credential instead of passkey.
  /// Use when the device does not support passkey or the user chose to set a password.
  Future<void> completeRecoveryWithPassword({
    required UserRegistrationChallenge challenge,
    required String credentialId,
    required String recoveryKey,
    required String newPassword,
  }) async {
    final credentialRequestData = await identitySigner.registerWithPassword(
      challenge: challenge.challenge,
      password: newPassword,
      username: username,
      credentialKind: CredentialKind.PasswordProtectedKey,
    );
    await _sendRecoveryWithCredential(
      challenge: challenge,
      credentialId: credentialId,
      recoveryKey: recoveryKey,
      firstFactorCredential: credentialRequestData,
    );
  }

  Future<void> _sendRecoveryWithCredential({
    required UserRegistrationChallenge challenge,
    required String credentialId,
    required String recoveryKey,
    required CredentialRequestData firstFactorCredential,
  }) async {
    final credentialJson = firstFactorCredential.toJson();
    final signedRecoveryPackage = await _signNewCredentials(
      encryptedKey: _resolveEncryptedRecoveryKey(
        challenge: challenge,
        credentialId: credentialId,
      ),
      recoveryKey: recoveryKey,
      credentialId: credentialId,
      newCredentials: {
        'firstFactorCredential': credentialJson,
      },
    );

    await dataSource.recoverUser(
      recoveryData: {
        'newCredentials': {
          'firstFactorCredential': credentialJson,
        },
        'recovery': signedRecoveryPackage.toJson(),
      },
      temporaryAuthenticationToken: challenge.temporaryAuthenticationToken!,
    );
  }

  Future<AssertionRequestData> _signNewCredentials({
    required String encryptedKey,
    required String recoveryKey,
    required String credentialId,
    required Map<String, dynamic> newCredentials,
  }) async {
    return identitySigner.signWithPassword(
      challenge: base64UrlEncode(utf8.encode(jsonEncode(newCredentials))),
      encryptedPrivateKey: encryptedKey,
      password: recoveryKey,
      credentialId: credentialId,
      credentialKind: CredentialKind.RecoveryKey,
    );
  }

  String _resolveEncryptedRecoveryKey({
    required UserRegistrationChallenge challenge,
    required String credentialId,
  }) {
    final allowedRecoveryCredentials = challenge.allowedRecoveryCredentials;
    if (allowedRecoveryCredentials == null || allowedRecoveryCredentials.isEmpty) {
      throw InvalidRecoveryCredentialsException(
        'Recovery challenge has no allowed recovery credentials. requestedCredentialId: '
        '${credentialId.trim().isEmpty ? '<empty>' : credentialId.trim()}',
      );
    }

    final normalizedCredentialId = credentialId.trim();
    if (normalizedCredentialId.isEmpty) {
      throw InvalidRecoveryCredentialsException(
        'Recovery credential id is empty',
      );
    }

    final recoveryCredential = allowedRecoveryCredentials.firstWhere(
      (recoveryCredential) => recoveryCredential.id.trim() == normalizedCredentialId,
      orElse: () => throw InvalidRecoveryCredentialsException(
        'Recovery credential id mismatch. requestedCredentialId: $normalizedCredentialId, '
        'allowedCredentialIds: ${allowedRecoveryCredentials.map((credential) => credential.id).join(',')}',
      ),
    );

    return recoveryCredential.encryptedRecoveryKey;
  }
}
