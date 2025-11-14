// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class SettingsRoutes {
  static const routes = <TypedRoute<RouteData>>[
    TypedGoRoute<SettingsRoute>(path: 'settings'),
    TypedGoRoute<AccountSettingsRoute>(path: 'account-settings'),
    TypedGoRoute<PrivacySettingsRoute>(path: 'privacy-settings'),
    TypedGoRoute<PushNotificationsSettingsRoute>(path: 'push-notifications-settings'),
    TypedGoRoute<AppLanguagesRoute>(path: 'app-language'),
    TypedGoRoute<ContentLanguagesRoute>(path: 'content-language'),
    TypedGoRoute<RelaySelectionRoute>(path: 'relay-selection'),
    TypedGoRoute<BlockedUsersRoute>(path: 'blocked-users'),
    TypedGoRoute<ConfirmLogoutRoute>(path: 'confirm-logout'),
    TypedGoRoute<DelegateAccessRoute>(path: 'delegate-access'),
    TypedGoRoute<SelectDelegateUserRoute>(path: 'select-delegate-user'),
    TypedGoRoute<DelegateUserSelectedRoute>(path: 'delegate-user-selected/:selectedUserPubkey'),
    TypedGoRoute<SwitchUserAccountRoute>(path: 'switch-user-account/:selectedUserPubkey'),
    ...ProtectAccountRoutes.routes,
  ];
}

class SettingsRoute extends BaseRouteData with _$SettingsRoute {
  SettingsRoute()
      : super(
          child: const SettingsModal(),
          type: IceRouteType.bottomSheet,
        );
}

class AppLanguagesRoute extends BaseRouteData with _$AppLanguagesRoute {
  AppLanguagesRoute()
      : super(
          child: const AppLanguageModal(),
          type: IceRouteType.bottomSheet,
        );
}

class ContentLanguagesRoute extends BaseRouteData with _$ContentLanguagesRoute {
  ContentLanguagesRoute()
      : super(
          child: const ContentLanguageModal(),
          type: IceRouteType.bottomSheet,
        );
}

class RelaySelectionRoute extends BaseRouteData with _$RelaySelectionRoute {
  RelaySelectionRoute()
      : super(
          child: const RelaySelectionModal(),
          type: IceRouteType.bottomSheet,
        );
}

class AccountSettingsRoute extends BaseRouteData with _$AccountSettingsRoute {
  AccountSettingsRoute()
      : super(
          child: const AccountSettingsModal(),
          type: IceRouteType.bottomSheet,
        );
}

class BlockedUsersRoute extends BaseRouteData with _$BlockedUsersRoute {
  BlockedUsersRoute()
      : super(
          child: const BlockedUsersModal(),
          type: IceRouteType.bottomSheet,
        );
}

class PrivacySettingsRoute extends BaseRouteData with _$PrivacySettingsRoute {
  PrivacySettingsRoute()
      : super(
          child: const PrivacySettingsModal(),
          type: IceRouteType.bottomSheet,
        );
}

class PushNotificationsSettingsRoute extends BaseRouteData with _$PushNotificationsSettingsRoute {
  PushNotificationsSettingsRoute()
      : super(
          child: const PushNotificationsSettings(),
          type: IceRouteType.bottomSheet,
        );
}

class ConfirmLogoutRoute extends BaseRouteData with _$ConfirmLogoutRoute {
  ConfirmLogoutRoute({required this.pubkey})
      : super(
          child: ConfirmLogoutModal(pubkey: pubkey),
          type: IceRouteType.bottomSheet,
        );

  final String pubkey;
}

class DelegateAccessRoute extends BaseRouteData with _$DelegateAccessRoute {
  DelegateAccessRoute()
      : super(
          child: const DelegateAccessModal(),
          type: IceRouteType.bottomSheet,
        );
}

class SelectDelegateUserRoute extends BaseRouteData with _$SelectDelegateUserRoute {
  SelectDelegateUserRoute()
      : super(
          child: const SelectDelegateUserModal(),
          type: IceRouteType.bottomSheet,
        );
}

class DelegateUserSelectedRoute extends BaseRouteData with _$DelegateUserSelectedRoute {
  DelegateUserSelectedRoute({required this.selectedUserPubkey})
      : super(
          child: DelegateUserSelectedModal(selectedUserPubkey: selectedUserPubkey),
          type: IceRouteType.bottomSheet,
        );

  final String selectedUserPubkey;
}

class SwitchUserAccountRoute extends BaseRouteData with _$SwitchUserAccountRoute {
  SwitchUserAccountRoute({required this.selectedUserPubkey})
      : super(
          child: SwitchUserAccountModal(selectedUserPubkey: selectedUserPubkey),
          type: IceRouteType.bottomSheet,
        );

  final String selectedUserPubkey;
}
