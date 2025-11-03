// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/credentials/create_new_credentials_service.dart';
import 'package:ion_identity_client/src/auth/services/credentials/create_recovery_credentials_service.dart';
import 'package:ion_identity_client/src/auth/services/credentials/data_sources/create_recovery_credentials_data_source.dart';
import 'package:ion_identity_client/src/auth/services/credentials/data_sources/get_credentials_data_source.dart';
import 'package:ion_identity_client/src/auth/services/credentials/get_credentials_service.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/data_sources/delegated_login_data_source.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/delegated_login_service.dart';
import 'package:ion_identity_client/src/auth/services/delete/data_sources/delete_user_data_source.dart';
import 'package:ion_identity_client/src/auth/services/delete/delete_service.dart';
import 'package:ion_identity_client/src/auth/services/extract_user_id/extract_user_id_service.dart';
import 'package:ion_identity_client/src/auth/services/key_service.dart';
import 'package:ion_identity_client/src/auth/services/login/data_sources/login_data_source.dart';
import 'package:ion_identity_client/src/auth/services/login/login_executors.dart';
import 'package:ion_identity_client/src/auth/services/login/login_service.dart';
import 'package:ion_identity_client/src/auth/services/logout/data_sources/logout_data_source.dart';
import 'package:ion_identity_client/src/auth/services/logout/logout_service.dart';
import 'package:ion_identity_client/src/auth/services/recover_user/data_sources/recover_user_data_source.dart';
import 'package:ion_identity_client/src/auth/services/recover_user/recover_user_service.dart';
import 'package:ion_identity_client/src/auth/services/register/data_sources/register_data_source.dart';
import 'package:ion_identity_client/src/auth/services/register/register_service.dart';
import 'package:ion_identity_client/src/auth/services/twofa/data_sources/twofa_data_source.dart';
import 'package:ion_identity_client/src/auth/services/twofa/twofa_service.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/user_action_signer_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/wallets_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_service_locator.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

class AuthClientServiceLocator {
  factory AuthClientServiceLocator() {
    return _instance;
  }

  AuthClientServiceLocator._internal();

  static final AuthClientServiceLocator _instance = AuthClientServiceLocator._internal();

  IONIdentityAuth auth({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return IONIdentityAuth(
      username: username,
      registerService: register(
        username: username,
        config: config,
        identitySigner: identitySigner,
      ),
      identitySigner: identitySigner,
      loginService: login(username: username, config: config, identitySigner: identitySigner),
      logoutService: logout(username: username, config: config),
      deleteService: delete(username: username, config: config),
      createRecoveryCredentialsService: createRecoveryCredentials(
        username: username,
        config: config,
        identitySigner: identitySigner,
      ),
      getCredentialsService: getCredentials(username: username, config: config),
      createNewCredentialsService: _createNewCredentials(
        username: username,
        config: config,
        identitySigner: identitySigner,
      ),
      recoverUserService: recoverUser(
        username: username,
        config: config,
        identitySigner: identitySigner,
      ),
      twoFAService: twoFA(username: username, config: config, identitySigner: identitySigner),
      delegatedLoginService: delegatedLogin(config: config),
      privateKeyStorage: IONIdentityServiceLocator.privateKeyStorage(),
      biometricsStateStorage: IONIdentityServiceLocator.biometricsStateStorage(),
      localPasskeyCredsStateStorage: IONIdentityServiceLocator.localPasskeyCredsStateStorage(),
    );
  }

  RegisterService register({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return RegisterService(
      username: username,
      identitySigner: identitySigner,
      dataSource: RegisterDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
      ),
      tokenStorage: IONIdentityServiceLocator.tokenStorage(),
    );
  }

  LoginService login({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return LoginService(
      username: username,
      dataSource: LoginDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
      ),
      tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      privateKeyStorage: IONIdentityServiceLocator.privateKeyStorage(),
      biometricsStateStorage: IONIdentityServiceLocator.biometricsStateStorage(),
      loginExecutorFactory: LoginExecutorFactory(
        identitySigner: identitySigner,
        biometricsStateStorage: IONIdentityServiceLocator.biometricsStateStorage(),
        privateKeyStorage: IONIdentityServiceLocator.privateKeyStorage(),
      ),
    );
  }

  LogoutService logout({
    required String username,
    required IONIdentityConfig config,
  }) {
    return LogoutService(
      username: username,
      dataSource: LogoutDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
      ),
      tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      privateKeyStorage: IONIdentityServiceLocator.privateKeyStorage(),
    );
  }

  DeleteService delete({
    required String username,
    required IONIdentityConfig config,
  }) {
    return DeleteService(
      username: username,
      dataSource: DeleteUserDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
      ),
      tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      privateKeyStorage: IONIdentityServiceLocator.privateKeyStorage(),
      biometricsStateStorage: IONIdentityServiceLocator.biometricsStateStorage(),
      extractUserIdService: AuthClientServiceLocator().extractUserId(),
    );
  }

  CreateRecoveryCredentialsService createRecoveryCredentials({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return CreateRecoveryCredentialsService(
      username: username,
      config: config,
      dataSource: CreateRecoveryCredentialsDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
      userActionSigner: UserActionSignerServiceLocator().userActionSigner(
        config: config,
        identitySigner: identitySigner,
      ),
      identitySigner: identitySigner,
      keyService: const KeyService(),
    );
  }

  GetCredentialsService getCredentials({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetCredentialsService(
      username: username,
      dataSource: GetCredentialsDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  CreateNewCredentialsService _createNewCredentials({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return CreateNewCredentialsService(
      username: username,
      config: config,
      dataSource: CreateRecoveryCredentialsDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
      userActionSigner: UserActionSignerServiceLocator().userActionSigner(
        config: config,
        identitySigner: identitySigner,
      ),
      identitySigner: identitySigner,
      localPasskeyCredsStateStorage: IONIdentityServiceLocator.localPasskeyCredsStateStorage(),
    );
  }

  RecoverUserService recoverUser({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return RecoverUserService(
      config: config,
      username: username,
      identitySigner: identitySigner,
      dataSource: RecoverUserDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
      ),
      keyService: const KeyService(),
    );
  }

  DelegatedLoginService delegatedLogin({
    required IONIdentityConfig config,
  }) {
    return DelegatedLoginService(
      dataSource: DelegatedLoginDataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
      tokenStorage: IONIdentityServiceLocator.tokenStorage(),
    );
  }

  TwoFAService twoFA({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return TwoFAService(
      username: username,
      dataSource: TwoFADataSource(
        networkClient: IONIdentityServiceLocator.networkClient(config: config),
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
      wallets: WalletsClientServiceLocator().wallets(
        username: username,
        config: config,
        identitySigner: identitySigner,
      ),
      extractUserIdService: extractUserId(),
    );
  }

  ExtractUserIdService extractUserId() => ExtractUserIdService(
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      );
}
