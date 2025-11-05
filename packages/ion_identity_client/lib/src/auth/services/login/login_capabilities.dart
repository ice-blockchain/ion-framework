// SPDX-License-Identifier: ice License 1.0

class LoginCapabilities {
  const LoginCapabilities({
    required this.supportsPasskey,
    required this.passwordFlowAvailable,
    required this.identityFound,
    this.twoFAOptionsCount,
  });

  final bool supportsPasskey;
  final bool passwordFlowAvailable;
  final bool identityFound;
  final int? twoFAOptionsCount;
}
