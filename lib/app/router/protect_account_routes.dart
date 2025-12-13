// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class ProtectAccountRoutes {
  static const routes = <TypedRoute<RouteData>>[
    TypedGoRoute<SecureAccountModalRoute>(path: 'secure-account-modal'),
    TypedGoRoute<SecureAccountOptionsRoute>(path: 'secure-account-options'),
    TypedGoRoute<SecureAccountErrorRoute>(path: 'secure-account-error'),
    TypedGoRoute<BackupOptionsRoute>(path: 'backup-options'),
    TypedGoRoute<BackupWithCloudDisabledRoute>(path: 'backup-cloud-disabled'),
    TypedGoRoute<BackupWithCloudRoute>(path: 'backup-with-cloud'),
    TypedGoRoute<BackupWithCloudSuccessRoute>(path: 'backup-with-cloud-success'),
    TypedGoRoute<BackupRecoveryKeysRoute>(path: 'backup-recovery-keys'),
    TypedGoRoute<CreateRecoveryKeyRoute>(path: 'recovery-keys-save'),
    TypedGoRoute<ValidateRecoveryKeyRoute>(path: 'recovery-keys-input'),
    TypedGoRoute<RecoveryKeysSuccessRoute>(path: 'recovery-keys-success'),
    TypedGoRoute<AuthenticatorSetupOptionsRoute>(path: 'authenticator-setup/options'),
    TypedGoRoute<AuthenticatorSetupInstructionsRoute>(path: 'authenticator-setup/instructions'),
    TypedGoRoute<AuthenticatorSetupCodeConfirmRoute>(path: 'authenticator-setup/confirmation'),
    TypedGoRoute<AuthenticatorSetupSuccessRoute>(path: 'authenticator-setup/success'),
    TypedGoRoute<AuthenticatorDeleteRoute>(path: 'authenticator-delete'),
    TypedGoRoute<AuthenticatorDeleteSuccessRoute>(path: 'authenticator-delete-success'),
    TypedGoRoute<EmailSetupRoute>(path: 'email-setup/:step'),
    TypedGoRoute<EmailEditRoute>(path: 'email-edit'),
    TypedGoRoute<EmailDeleteRoute>(path: 'email-delete'),
    TypedGoRoute<PhoneSetupRoute>(path: 'phone-setup/:step'),
    TypedGoRoute<PhoneEditRoute>(path: 'phone-edit'),
    TypedGoRoute<PhoneDeleteRoute>(path: 'phone-delete'),
    TypedGoRoute<SelectCountriesRoute>(path: 'select-countries'),
  ];
}

class SecureAccountOptionsRoute extends BaseRouteData with _$SecureAccountOptionsRoute {
  SecureAccountOptionsRoute({this.showCloseButton = true})
      : super(
          child: SecureAccountOptionsPage(showCloseButton: showCloseButton),
          type: IceRouteType.bottomSheet,
        );

  bool showCloseButton;
}

class SecureAccountModalRoute extends BaseRouteData with _$SecureAccountModalRoute {
  SecureAccountModalRoute()
      : super(
          child: const SecureAccountModal(),
          type: IceRouteType.bottomSheet,
        );
}

class SecureAccountErrorRoute extends BaseRouteData with _$SecureAccountErrorRoute {
  SecureAccountErrorRoute()
      : super(
          child: const SecureAccountErrorAlert(),
          type: IceRouteType.bottomSheet,
        );
}

class BackupOptionsRoute extends BaseRouteData with _$BackupOptionsRoute {
  BackupOptionsRoute()
      : super(
          child: const BackupOptionsPage(),
          type: IceRouteType.bottomSheet,
        );
}

class BackupWithCloudDisabledRoute extends BaseRouteData with _$BackupWithCloudDisabledRoute {
  BackupWithCloudDisabledRoute()
      : super(
          child: const CloudDisabledModal(),
          type: IceRouteType.bottomSheet,
        );
}

class BackupWithCloudRoute extends BaseRouteData with _$BackupWithCloudRoute {
  BackupWithCloudRoute()
      : super(
          child: const BackupWithCloudPage(),
          type: IceRouteType.bottomSheet,
        );
}

class BackupWithCloudSuccessRoute extends BaseRouteData with _$BackupWithCloudSuccessRoute {
  BackupWithCloudSuccessRoute()
      : super(
          child: const BackupWithCloudSuccessPage(),
          type: IceRouteType.bottomSheet,
        );
}

class BackupRecoveryKeysRoute extends BaseRouteData with _$BackupRecoveryKeysRoute {
  BackupRecoveryKeysRoute()
      : super(
          child: const BackupRecoveryKeysModal(),
          type: IceRouteType.bottomSheet,
        );
}

class CreateRecoveryKeyRoute extends BaseRouteData with _$CreateRecoveryKeyRoute {
  CreateRecoveryKeyRoute()
      : super(
          child: const CreateRecoveryKeyPage(),
          type: IceRouteType.bottomSheet,
        );
}

class ValidateRecoveryKeyRoute extends BaseRouteData with _$ValidateRecoveryKeyRoute {
  ValidateRecoveryKeyRoute()
      : super(
          child: const ValidateRecoveryKeyPage(),
          type: IceRouteType.bottomSheet,
        );
}

class RecoveryKeysSuccessRoute extends BaseRouteData with _$RecoveryKeysSuccessRoute {
  RecoveryKeysSuccessRoute()
      : super(
          child: const RecoveryKeysSuccessPage(),
          type: IceRouteType.bottomSheet,
        );
}

class AuthenticatorSetupOptionsRoute extends BaseRouteData with _$AuthenticatorSetupOptionsRoute {
  AuthenticatorSetupOptionsRoute()
      : super(
          child: const AuthenticatorSetupOptionsPage(),
          type: IceRouteType.bottomSheet,
        );
}

class AuthenticatorSetupInstructionsRoute extends BaseRouteData
    with _$AuthenticatorSetupInstructionsRoute {
  AuthenticatorSetupInstructionsRoute()
      : super(
          child: const AuthenticatorSetupInstructionsPage(),
          type: IceRouteType.bottomSheet,
        );
}

class AuthenticatorSetupCodeConfirmRoute extends BaseRouteData
    with _$AuthenticatorSetupCodeConfirmRoute {
  AuthenticatorSetupCodeConfirmRoute()
      : super(
          child: const AuthenticatorSetupCodeConfirmPage(),
          type: IceRouteType.bottomSheet,
        );
}

class AuthenticatorSetupSuccessRoute extends BaseRouteData with _$AuthenticatorSetupSuccessRoute {
  AuthenticatorSetupSuccessRoute()
      : super(
          child: const AuthenticatorSetupSuccessPage(),
          type: IceRouteType.bottomSheet,
        );
}

class AuthenticatorDeleteRoute extends BaseRouteData with _$AuthenticatorDeleteRoute {
  AuthenticatorDeleteRoute()
      : super(
          child: const AuthenticatorDeletePage(),
          type: IceRouteType.bottomSheet,
        );
}

class AuthenticatorDeleteSuccessRoute extends BaseRouteData with _$AuthenticatorDeleteSuccessRoute {
  AuthenticatorDeleteSuccessRoute()
      : super(
          child: const AuthenticatorDeleteSuccessPage(),
          type: IceRouteType.bottomSheet,
        );
}

class EmailSetupRoute extends BaseRouteData with _$EmailSetupRoute {
  EmailSetupRoute({required this.step, this.email})
      : super(
          child: EmailSetupPage(step, email),
          type: IceRouteType.bottomSheet,
        );

  final EmailSetupSteps step;
  String? email;
}

class EmailEditRoute extends BaseRouteData with _$EmailEditRoute {
  EmailEditRoute()
      : super(
          child: const EmailEditPage(),
          type: IceRouteType.bottomSheet,
        );
}

class EmailDeleteRoute extends BaseRouteData with _$EmailDeleteRoute {
  EmailDeleteRoute()
      : super(
          child: const EmailDeletePage(),
          type: IceRouteType.bottomSheet,
        );
}

class PhoneSetupRoute extends BaseRouteData with _$PhoneSetupRoute {
  PhoneSetupRoute({required this.step, this.phone})
      : super(
          child: PhoneSetupPage(step, phone),
          type: IceRouteType.bottomSheet,
        );

  final PhoneSetupSteps step;
  String? phone;
}

class PhoneEditRoute extends BaseRouteData with _$PhoneEditRoute {
  PhoneEditRoute()
      : super(
          child: const PhoneEditPage(),
          type: IceRouteType.bottomSheet,
        );
}

class PhoneDeleteRoute extends BaseRouteData with _$PhoneDeleteRoute {
  PhoneDeleteRoute()
      : super(
          child: const PhoneDeletePage(),
          type: IceRouteType.bottomSheet,
        );
}

class SelectCountriesRoute extends BaseRouteData with _$SelectCountriesRoute {
  SelectCountriesRoute()
      : super(
          child: const SelectCountryPage(),
          type: IceRouteType.bottomSheet,
        );
}
