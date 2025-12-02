// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_account_modal_provider.r.g.dart';

class SwitchAccountModalState {
  SwitchAccountModalState({
    required this.identityKeyNames,
    required this.currentIdentityKeyName,
  });

  final List<String> identityKeyNames;
  final String? currentIdentityKeyName;

  SwitchAccountModalState copyWith({
    List<String>? identityKeyNames,
    String? currentIdentityKeyName,
  }) {
    return SwitchAccountModalState(
      identityKeyNames: identityKeyNames ?? this.identityKeyNames,
      currentIdentityKeyName: currentIdentityKeyName ?? this.currentIdentityKeyName,
    );
  }
}

@riverpod
class SwitchAccountModalNotifier extends _$SwitchAccountModalNotifier {
  @override
  Future<SwitchAccountModalState> build() async {
    final authState = await ref.watch(authProvider.future);
    final authenticatedIdentityKeyNames = authState.authenticatedIdentityKeyNames;
    final currentIdentityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);

    return SwitchAccountModalState(
      identityKeyNames: authenticatedIdentityKeyNames,
      currentIdentityKeyName: currentIdentityKeyName,
    );
  }

  Future<void> setCurrentUser(String identityKeyName) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    if (currentState.currentIdentityKeyName == identityKeyName) {
      ref.read(userSwitchInProgressProvider.notifier).completeSwitching();
    } else {
      await ref.read(authProvider.notifier).setCurrentUser(identityKeyName);
    }
  }

  Future<void> clearCurrentUserForAuthentication() async {
    ref.read(userSwitchInProgressProvider.notifier).startSwitching();
  }
}

@riverpod
Future<UserDetails> switchAccountModalUserDetails(
  Ref ref,
  String identityKeyName,
) async {
  final ionIdentity = await ref.watch(ionIdentityProvider.future);
  return ionIdentity(username: identityKeyName).users.currentUserDetails();
}
