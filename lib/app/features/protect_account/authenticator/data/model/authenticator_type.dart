// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/generated/assets.gen.dart';

enum AuthenticatorType {
  google,
  microsoft,
  lastpass,
  authy,
  userLockPush;

  String getDisplayName(BuildContext context) => switch (this) {
        AuthenticatorType.google => context.i18n.authenticator_google,
        AuthenticatorType.microsoft => context.i18n.authenticator_microsoft,
        AuthenticatorType.lastpass => context.i18n.authenticator_lastpass,
        AuthenticatorType.authy => context.i18n.authenticator_authy,
        AuthenticatorType.userLockPush => context.i18n.authenticator_userLockPush,
      };

  String get iconAsset {
    return switch (this) {
      AuthenticatorType.google => Assets.svg.icon2faGoogleauth,
      AuthenticatorType.microsoft => Assets.svg.icon2famicrosoft,
      AuthenticatorType.lastpass => Assets.svg.icon2faLastpass,
      AuthenticatorType.authy => Assets.svg.icon2faAuthy,
      AuthenticatorType.userLockPush => Assets.svg.icon2faUserlock,
    };
  }

  String get androidPackageName {
    return switch (this) {
      AuthenticatorType.google => 'com.google.android.apps.authenticator2',
      AuthenticatorType.microsoft => 'com.azure.authenticator',
      AuthenticatorType.lastpass => 'com.lastpass.authenticator',
      AuthenticatorType.authy => 'com.authy.authy',
      AuthenticatorType.userLockPush => 'com.isdecisions.userlockpush',
    };
  }

  String get iosAppUrlScheme {
    return switch (this) {
      AuthenticatorType.google => 'googleauthenticator://',
      AuthenticatorType.microsoft => 'msauthv3://',
      AuthenticatorType.lastpass => 'lastpassmfa://',
      AuthenticatorType.authy => 'authy://',
      AuthenticatorType.userLockPush => 'userlock://',
    };
  }

  String get appStoreLink {
    return switch (this) {
      AuthenticatorType.google => 'https://apps.apple.com/us/app/google-authenticator/id388497605',
      AuthenticatorType.microsoft =>
        'https://apps.apple.com/us/app/microsoft-authenticator/id983156458',
      AuthenticatorType.lastpass =>
        'https://apps.apple.com/us/app/lastpass-authenticator/id1079110004',
      AuthenticatorType.authy => 'https://apps.apple.com/us/app/authy/id494168017',
      AuthenticatorType.userLockPush => 'https://apps.apple.com/us/app/userlock-push/id1633085926',
    };
  }
}
