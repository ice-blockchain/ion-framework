// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';

part 'security_methods.f.freezed.dart';

@freezed
class SecurityMethods with _$SecurityMethods {
  const factory SecurityMethods({
    @Default(false) bool isBackupEnabled,
    @Default(false) bool isEmailEnabled,
    @Default(false) bool isAuthenticatorEnabled,
    @Default(false) bool isPhoneEnabled,
  }) = _SecurityMethods;

  const SecurityMethods._();

  List<TwoFaType> get enabledTypes => [
        if (isAuthenticatorEnabled) TwoFaType.auth,
        if (isEmailEnabled) TwoFaType.email,
        if (isPhoneEnabled) TwoFaType.sms,
      ];
}
