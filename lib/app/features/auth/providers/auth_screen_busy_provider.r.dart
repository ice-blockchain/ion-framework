// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/bool.dart';
import 'package:ion/app/features/auth/providers/auth_flow_action_notifier.r.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/login_action_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_screen_busy_provider.r.g.dart';

@riverpod
bool authScreenBusy(Ref ref) {
  final authState = ref.watch(authProvider);
  final isUserSwitching = ref.watch(userSwitchInProgressProvider).isSwitchingProgress;

  final hasAuthorizedUsers =
      (authState.valueOrNull?.authenticatedIdentityKeyNames.isNotEmpty).falseOrValue;

  final loginLoading = ref.watch(loginActionNotifierProvider).isLoading;
  final registerLoading = ref.watch(authFlowActionNotifierProvider).isLoading;

  /// Busy while a sign-up/login attempt is in progress, while the app is switching users,
  /// or after login succeeded (authorized user exists) but routing hasn't moved away
  /// from the auth screen yet.
  return isUserSwitching || hasAuthorizedUsers || loginLoading || registerLoading;
}
