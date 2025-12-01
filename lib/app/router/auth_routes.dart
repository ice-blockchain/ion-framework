// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class AuthRoutes {
  static const authPrefix = 'auth';

  static const onboardingPrefix = 'onboarding';

  static const routes = <TypedRoute<RouteData>>[
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<GetStartedRoute>(path: '$authPrefix/get-started'),
        TypedGoRoute<SignUpPasskeyRoute>(path: '$authPrefix/sign-up-passkey'),
        TypedGoRoute<SignUpPasswordRoute>(path: '$authPrefix/sign-up-password'),
        TypedGoRoute<SignUpRestrictedRoute>(path: '$authPrefix/sign-up-restricted'),
        TypedGoRoute<SignUpEarlyAccessRoute>(path: '$authPrefix/sign-up-early-access'),
        TypedGoRoute<RestoreMenuRoute>(path: '$authPrefix/restore-menu'),
        TypedGoRoute<RestoreCredsRoute>(path: '$authPrefix/restore-creds'),
        TypedGoRoute<RecoverUserRoute>(path: '$authPrefix/recover-user'),
        TypedGoRoute<RestoreFromCloudRoute>(path: '$authPrefix/restore-from-cloud'),
        TypedGoRoute<RestoreFromCloudNoKeysRoute>(path: '$authPrefix/restore-from-cloud-no-keys'),
        TypedGoRoute<RecoverUserSuccessRoute>(path: '$authPrefix/recover-user-success'),
        TypedGoRoute<SelectLanguagesRoute>(path: '$onboardingPrefix/select-languages'),
        TypedGoRoute<FillProfileRoute>(path: '$onboardingPrefix/fill-profile'),
        TypedGoRoute<DiscoverCreatorsRoute>(path: '$onboardingPrefix/discover-creators'),
        TypedGoRoute<NotificationsRoute>(path: '$onboardingPrefix/notifications'),
        TypedGoRoute<SwitchAccountAuthRoute>(path: '$authPrefix/switch-account'),
      ],
    ),
  ];
}

class GetStartedRoute extends BaseRouteData with _$GetStartedRoute {
  GetStartedRoute()
      : super(
          child: const GetStartedPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SignUpPasskeyRoute extends BaseRouteData with _$SignUpPasskeyRoute {
  SignUpPasskeyRoute()
      : super(
          child: const SignUpPasskeyPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SignUpPasswordRoute extends BaseRouteData with _$SignUpPasswordRoute {
  SignUpPasswordRoute()
      : super(
          child: const SignUpPasswordPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SignUpRestrictedRoute extends BaseRouteData with _$SignUpRestrictedRoute {
  SignUpRestrictedRoute()
      : super(
          child: const SignUpRestrictedPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SignUpEarlyAccessRoute extends BaseRouteData with _$SignUpEarlyAccessRoute {
  SignUpEarlyAccessRoute()
      : super(
          child: const SignUpEarlyAccessPage(),
          type: IceRouteType.bottomSheet,
        );
}

class RestoreMenuRoute extends BaseRouteData with _$RestoreMenuRoute {
  RestoreMenuRoute()
      : super(
          child: const RestoreMenuPage(),
          type: IceRouteType.bottomSheet,
        );
}

class RestoreCredsRoute extends BaseRouteData with _$RestoreCredsRoute {
  RestoreCredsRoute()
      : super(
          child: const RestoreCredsPage(),
          type: IceRouteType.bottomSheet,
        );
}

class RecoverUserSuccessRoute extends BaseRouteData with _$RecoverUserSuccessRoute {
  RecoverUserSuccessRoute()
      : super(
          child: const RecoverUserSuccessPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SelectLanguagesRoute extends BaseRouteData with _$SelectLanguagesRoute {
  SelectLanguagesRoute()
      : super(
          child: const SelectLanguages(),
          type: IceRouteType.bottomSheet,
        );
}

class FillProfileRoute extends BaseRouteData with _$FillProfileRoute {
  FillProfileRoute()
      : super(
          child: const FillProfile(),
          type: IceRouteType.bottomSheet,
        );
}

class DiscoverCreatorsRoute extends BaseRouteData with _$DiscoverCreatorsRoute {
  DiscoverCreatorsRoute()
      : super(
          child: const DiscoverCreators(),
          type: IceRouteType.bottomSheet,
        );
}

class NotificationsRoute extends BaseRouteData with _$NotificationsRoute {
  NotificationsRoute()
      : super(
          child: const TurnOnNotifications(),
          type: IceRouteType.bottomSheet,
        );
}

class RecoverUserRoute extends BaseRouteData with _$RecoverUserRoute {
  RecoverUserRoute()
      : super(
          child: const RecoverUserPage(),
          type: IceRouteType.bottomSheet,
        );
}

class RestoreFromCloudRoute extends BaseRouteData with _$RestoreFromCloudRoute {
  RestoreFromCloudRoute()
      : super(
          child: const RestoreFromCloudPage(),
          type: IceRouteType.bottomSheet,
        );
}

class RestoreFromCloudNoKeysRoute extends BaseRouteData with _$RestoreFromCloudNoKeysRoute {
  RestoreFromCloudNoKeysRoute()
      : super(
          child: const RestoreFromCloudNoKeysAvailableModal(),
          type: IceRouteType.bottomSheet,
        );
}

class SwitchAccountAuthRoute extends BaseRouteData with _$SwitchAccountAuthRoute {
  SwitchAccountAuthRoute()
      : super(
          child: const SwitchAccountModal(enableAccountManagement: false),
          type: IceRouteType.bottomSheet,
        );
}
