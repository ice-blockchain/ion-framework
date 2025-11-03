// SPDX-License-Identifier: ice License 1.0

typedef GetPasswordCallback = Future<String> Function();

class LoginAuthConfig {
  const LoginAuthConfig({
    this.getPassword,
    this.localisedReasonForBiometrics,
    this.localisedCancelForBiometrics,
  });

  final GetPasswordCallback? getPassword;
  final String? localisedReasonForBiometrics;
  final String? localisedCancelForBiometrics;
}


