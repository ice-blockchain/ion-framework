// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/credentials/data_sources/create_recovery_credentials_data_source.dart';
import 'package:ion_identity_client/src/core/storage/local_passkey_creds_state_storage.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';
import 'package:ion_identity_client/src/signer/user_action_signer.dart';
import 'package:uuid/uuid.dart';

class CreateNewCredentialsService {
  CreateNewCredentialsService({
    required this.username,
    required this.config,
    required this.dataSource,
    required this.userActionSigner,
    required this.identitySigner,
    required this.localPasskeyCredsStateStorage,
  });

  final String username;
  final IONIdentityConfig config;
  final CreateRecoveryCredentialsDataSource dataSource;
  final UserActionSigner userActionSigner;
  final IdentitySigner identitySigner;
  final LocalPasskeyCredsStateStorage localPasskeyCredsStateStorage;

  Future<void> _createNewCredentials(
    OnVerifyIdentity<CredentialRequestData> onVerifyIdentity,
  ) async {
    final credentialChallenge = await dataSource.createCredentialInit(username: username);

    final credentialRequestData = await onVerifyIdentity(
      onPasswordFlow: ({required String password}) {
        return identitySigner.registerWithPassword(
          challenge: credentialChallenge.challenge,
          password: password,
          username: username,
          credentialKind: CredentialKind.PasswordProtectedKey,
        );
      },
      onPasskeyFlow: () {
        return identitySigner.registerWithPasskey(
          UserRegistrationChallenge(
            null,
            credentialChallenge.rp,
            credentialChallenge.user,
            null,
            null,
            credentialChallenge.challenge,
            credentialChallenge.authenticatorSelection,
            credentialChallenge.attestation,
            credentialChallenge.pubKeyCredParams,
            credentialChallenge.excludeCredentials ?? [],
            null,
          ),
        );
      },
      onBiometricsFlow: ({required String localisedReason, required String localisedCancel}) {
        throw UnimplementedError('Cannot register with biometrics');
      },
    );

    final credentialRequest = dataSource.buildCreateCredentialSigningRequest(
      username,
      CredentialRequestData(
        challengeIdentifier: credentialChallenge.challengeIdentifier,
        credentialName: generateCredentialName(),
        credentialKind: credentialRequestData.credentialKind,
        credentialInfo: credentialRequestData.credentialInfo,
        encryptedPrivateKey: credentialRequestData.encryptedPrivateKey,
      ),
    );

    await userActionSigner.signWithPasskey(
      credentialRequest,
      (_) => null,
    );
  }

  Future<void> createLocalPasskeyCredentials() async {
    try {
      await _createNewCredentials(
        ({required onPasskeyFlow, required onPasswordFlow, required onBiometricsFlow}) =>
            onPasskeyFlow(),
      );
      return localPasskeyCredsStateStorage.updateLocalPasskeyCredsState(
        username: username,
        state: LocalPasskeyCredsState.accepted,
      );
    } catch (e) {
      await localPasskeyCredsStateStorage.updateLocalPasskeyCredsState(
        username: username,
        state: LocalPasskeyCredsState.failed,
      );
      rethrow;
    }
  }

  String generateCredentialName() => const Uuid().v4().toUpperCase();
}
