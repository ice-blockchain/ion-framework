// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/protect_account/backup/providers/cloud_stored_recovery_keys_names_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/data/models/security_methods.f.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/recovery_credentials_enabled_notifier.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/recovery_keys_completed_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/user_details_provider.r.dart';
import 'package:ion/app/utils/predicates.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'security_account_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<SecurityMethods> securityAccountController(Ref ref) async {
  final (userDetails, recoveryCredentialsEnabled, hasCurrentUserBackup, recoveryKeysCompleted) =
      await (
    ref.watch(userDetailsProvider.future),
    ref.watch(recoveryCredentialsEnabledProvider.future),
    ref.watch(hasCurrentUserBackupInCloudProvider.future),
    ref.watch(recoveryKeysCompletedProvider.future),
  ).wait;
  final twoFaOptions = userDetails.twoFaOptions ?? [];

  return SecurityMethods(
    isEmailEnabled: twoFaOptions.any(startsWith(const TwoFAType.email().option)),
    isPhoneEnabled: twoFaOptions.any(startsWith(const TwoFAType.sms().option)),
    isAuthenticatorEnabled: twoFaOptions.any(startsWith(const TwoFAType.authenticator().option)),
    isBackupEnabled: recoveryCredentialsEnabled && (hasCurrentUserBackup || recoveryKeysCompleted),
    hasCloudEnabled: hasCurrentUserBackup,
    hasRecoveryKeysEnabled: recoveryKeysCompleted,
  );
}

@riverpod
Future<bool> is2FAEnabledForCurrentUser(Ref ref) async {
  final securityMethodsState = await ref.watch(securityAccountControllerProvider.future);
  return securityMethodsState.enabledTypes.isNotEmpty;
}

@riverpod
Future<bool> isBackupEnabledForCurrentUser(Ref ref) async {
  final securityMethodsState = await ref.watch(securityAccountControllerProvider.future);
  return securityMethodsState.isBackupEnabled;
}
