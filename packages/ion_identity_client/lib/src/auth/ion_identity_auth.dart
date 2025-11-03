// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/credentials/create_new_credentials_service.dart';
import 'package:ion_identity_client/src/auth/services/credentials/create_recovery_credentials_service.dart';
import 'package:ion_identity_client/src/auth/services/credentials/get_credentials_service.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/delegated_login_service.dart';
import 'package:ion_identity_client/src/auth/services/delete/delete_service.dart';
import 'package:ion_identity_client/src/auth/services/login/login_service.dart';
import 'package:ion_identity_client/src/auth/services/logout/logout_service.dart';
import 'package:ion_identity_client/src/auth/services/recover_user/recover_user_service.dart';
import 'package:ion_identity_client/src/auth/services/register/register_service.dart';
import 'package:ion_identity_client/src/auth/services/twofa/twofa_service.dart';
import 'package:ion_identity_client/src/core/storage/biometrics_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/local_passkey_creds_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

/// A class that handles user authentication processes, including user registration,
/// login, and logout.
class IONIdentityAuth {
  /// Constructs an [IONIdentityAuth] instance with the provided services and token storage.
  ///
  /// The [username] is the identifier for the user.
  /// The [registerService] handles user registration.
  /// The [loginService] handles user login.
  /// The [privateKeyStorage] manages the storage of authentication tokens.
  /// The [createRecoveryCredentialsService] handles the creation of recovery credentials.
  IONIdentityAuth({
    required this.username,
    required this.identitySigner,
    required this.registerService,
    required this.loginService,
    required this.logoutService,
    required this.deleteService,
    required this.privateKeyStorage,
    required this.biometricsStateStorage,
    required this.localPasskeyCredsStateStorage,
    required this.createRecoveryCredentialsService,
    required this.getCredentialsService,
    required this.createNewCredentialsService,
    required this.recoverUserService,
    required this.delegatedLoginService,
    required this.twoFAService,
  });

  final RegisterService registerService;
  final IdentitySigner identitySigner;
  final LoginService loginService;
  final LogoutService logoutService;
  final DeleteService deleteService;
  final CreateRecoveryCredentialsService createRecoveryCredentialsService;
  final GetCredentialsService getCredentialsService;
  final CreateNewCredentialsService createNewCredentialsService;
  final RecoverUserService recoverUserService;
  final DelegatedLoginService delegatedLoginService;
  final TwoFAService twoFAService;
  final PrivateKeyStorage privateKeyStorage;
  final BiometricsStateStorage biometricsStateStorage;
  final LocalPasskeyCredsStateStorage localPasskeyCredsStateStorage;

  final String username;

  Future<void> verifyEmailEarlyAccess({
    required String email,
  }) =>
      registerService.verifyEmailEarlyAccess(email: email);

  Future<void> registerUser(String? earlyAccessEmail) =>
      registerService.registerUser(earlyAccessEmail);

  Future<void> registerUserWithPassword(String password, String? earlyAccessEmail) =>
      registerService.registerWithPassword(password, earlyAccessEmail);

  Future<void> verifyUserLoginFlow() => loginService.verifyUserLoginFlow();

  Future<void> login({
    required LoginAuthConfig config,
    required List<TwoFAType> twoFATypes,
    required bool localCredsOnly,
  }) =>
      loginService.login(
        config: config,
        twoFATypes: twoFATypes,
        localCredsOnly: localCredsOnly,
      );

  Future<void> logOut() => logoutService.logOut();

  Future<void> deleteUser({required String base64Kind5Event}) =>
      deleteService.deleteUser(base64Kind5Event: base64Kind5Event);

  Future<bool> isPasskeyAvailable() => identitySigner.isPasskeyAvailable();

  bool isPasswordFlowUser() => privateKeyStorage.getPrivateKey(username: username) != null;

  BiometricsState? getBiometricsState() =>
      biometricsStateStorage.getBiometricsState(username: username);

  Future<void> rejectToUseBiometrics() => identitySigner.rejectToUseBiometrics(username);

  Future<void> enrollToUseBiometrics({required String localisedReason, required String password}) =>
      identitySigner.enrollToUseBiometrics(
        password: password,
        username: username,
        localisedReason: localisedReason,
      );

  LocalPasskeyCredsState? getLocalPasskeyCredsState() =>
      localPasskeyCredsStateStorage.getLocalPasskeyCredsState(username: username);

  Future<void> rejectToCreateLocalPasskeyCreds() =>
      identitySigner.rejectToCreateLocalPasskeyCreds(username);

  Future<RecoveryCredentials> createRecoveryCredentials(
    OnVerifyIdentity<CredentialResponse> onVerifyIdentity,
  ) =>
      createRecoveryCredentialsService.createRecoveryCredentials(onVerifyIdentity);

  Future<void> createLocalPasskeyCreds() =>
      createNewCredentialsService.createLocalPasskeyCredentials();

  Future<UserRegistrationChallenge> initRecovery({
    required String credentialId,
    List<TwoFAType> twoFATypes = const [],
  }) =>
      recoverUserService.initRecovery(
        credentialId: credentialId,
        twoFATypes: twoFATypes,
      );

  Future<void> completeRecovery({
    required UserRegistrationChallenge challenge,
    required String credentialId,
    required String recoveryKey,
  }) =>
      recoverUserService.completeRecovery(
        challenge: challenge,
        credentialId: credentialId,
        recoveryKey: recoveryKey,
      );

  Future<UserToken> delegatedLogin() async =>
      delegatedLoginService.delegatedLogin(username: username);

  Future<String?> requestTwoFACode({
    required TwoFAType twoFAType,
    required String? signature,
    Map<String, String>? verificationCodes,
    String? recoveryIdentityKeyName,
    String? twoFaValueToReplace,
  }) =>
      twoFAService.requestTwoFACode(
        twoFAType: twoFAType,
        signature: signature,
        verificationCodes: verificationCodes,
        recoveryIdentityKeyName: recoveryIdentityKeyName,
        twoFaValueToReplace: twoFaValueToReplace,
      );

  Future<void> verifyTwoFA(TwoFAType twoFAType) => twoFAService.verifyTwoFA(twoFAType);

  Future<void> deleteTwoFA({
    required TwoFAType twoFAType,
    required String? signature,
    List<TwoFAType> verificationCodes = const [],
  }) =>
      twoFAService.deleteTwoFA(
        twoFAType: twoFAType,
        signature: signature,
        verificationCodes: verificationCodes,
      );

  Future<String> generateSignature(
    OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity,
  ) =>
      twoFAService.generateSignature(onVerifyIdentity);

  Future<List<Credential>> getCredentialsList() => getCredentialsService.getCredentialsList();
}
