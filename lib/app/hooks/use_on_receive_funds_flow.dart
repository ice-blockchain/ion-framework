// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/security_account_provider.r.dart';
import 'package:ion/app/features/user/providers/user_verify_identity_provider.r.dart';

void Function() useOnReceiveFundsFlow({
  required void Function() onReceive,
  required void Function() onNeedToEnable2FA,
  required WidgetRef ref,
}) {
  final isAccountSecured = ref.watch(isCurrentUserSecuredProvider).value ?? false;

  final isPasswordFlowUser = ref.watch(isPasswordFlowUserProvider).value ?? false;
  final forceSecurityEnabled =
      ref.watch(feedConfigProvider).valueOrNull?.forceSecurityEnabled ?? true;

  return () {
    if ((isPasswordFlowUser || forceSecurityEnabled) && !isAccountSecured) {
      onNeedToEnable2FA();
    } else {
      onReceive();
    }
  };
}
