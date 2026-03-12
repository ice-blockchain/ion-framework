// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_flow_action_notifier.r.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/login_action_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_screen_busy_provider.r.g.dart';

@riverpod
bool authScreenBusy(Ref ref) {
  final authState = ref.watch(authProvider);
  final isUserSwitching =
      ref.watch(userSwitchInProgressProvider).isSwitchingProgress;

  final hasAuthorizedUsers =
      authState.valueOrNull?.authenticatedIdentityKeyNames.isNotEmpty ?? false;
  final loginLoading = ref.watch(loginActionNotifierProvider).isLoading;
  final registerLoading = ref.watch(authFlowActionNotifierProvider).isLoading;

  /// Keep auth screens in loading state while:
  /// - sign-up/login is in progress, or
  /// - auth already succeeded (authorized user exists) but routing is still resolving.
  ///
  /// Do not block account switching flow before login starts.
  final waitingForPostAuthRouting = hasAuthorizedUsers && !isUserSwitching;

  return loginLoading || registerLoading || waitingForPostAuthRouting;
}
