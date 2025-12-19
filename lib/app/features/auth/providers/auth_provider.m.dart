// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/local_passkey_creds_provider.r.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/push_subscription_sync_provider.r.dart';
import 'package:ion/app/features/user/providers/biometrics_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.m.freezed.dart';
part 'auth_provider.m.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required List<String> authenticatedIdentityKeyNames,
    required bool suggestToAddBiometrics,
    required bool suggestToCreateLocalPasskeyCreds,
    required bool hasEventSigner,
  }) = _AuthState;

  const AuthState._();

  bool get isAuthenticated {
    return authenticatedIdentityKeyNames.isNotEmpty &&
        !suggestToAddBiometrics &&
        !suggestToCreateLocalPasskeyCreds &&
        hasEventSigner;
  }
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<AuthState> build() async {
    final authenticatedIdentityKeyNames =
        await ref.watch(authenticatedIdentityKeyNamesStreamProvider.future);
    final savedIdentityKeyName = await ref.watch(currentIdentityKeyNameStoreProvider.future);

    final currentIdentityKeyName = authenticatedIdentityKeyNames.contains(savedIdentityKeyName)
        ? savedIdentityKeyName
        : authenticatedIdentityKeyNames.lastOrNull;
    final biometricsStates = await ref.watch(biometricsStatesStreamProvider.future);
    final localPasskeyCredsStates = await ref.watch(localPasskeyCredsStatesStreamProvider.future);
    final userBiometricsState =
        currentIdentityKeyName != null ? biometricsStates[currentIdentityKeyName] : null;
    final userLocalPasskeyCredsState =
        currentIdentityKeyName != null ? localPasskeyCredsStates[currentIdentityKeyName] : null;
    final eventSigner = currentIdentityKeyName != null
        ? await ref
            .watch(ionConnectEventSignerProvider(currentIdentityKeyName).notifier)
            .initEventSigner()
        : null;

    if (currentIdentityKeyName != null) {
      unawaited(
        ref
            .watch(currentIdentityKeyNameStoreProvider.notifier)
            .setCurrentIdentityKeyNameForNotificationServiceExtension(currentIdentityKeyName),
      );

      unawaited(
        ref
            .read(currentIdentityKeyNameSelectorProvider.notifier)
            .setCurrentIdentityKeyName(currentIdentityKeyName),
      );
    }

    listenSelf((_, next) async {
      if (next.valueOrNull?.authenticatedIdentityKeyNames == null ||
          next.valueOrNull!.authenticatedIdentityKeyNames.isEmpty) {
        await Future<void>.delayed(const Duration(seconds: 1));
        unawaited(
          ref.read(currentIdentityKeyNameSelectorProvider.notifier).setCurrentIdentityKeyName(null),
        );
      }
    });
    return AuthState(
      authenticatedIdentityKeyNames: authenticatedIdentityKeyNames.toList(),
      suggestToAddBiometrics: userBiometricsState == BiometricsState.canSuggest,
      suggestToCreateLocalPasskeyCreds:
          userLocalPasskeyCredsState == LocalPasskeyCredsState.canSuggest,
      hasEventSigner: eventSigner != null,
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    final currentUser = ref.read(currentIdentityKeyNameSelectorProvider);
    if (currentUser == null) return;

    final authenticatedIdentityKeyNames = state.valueOrNull?.authenticatedIdentityKeyNames ?? [];
    if (authenticatedIdentityKeyNames.length > 1) {
      ref.read(userSwitchInProgressProvider.notifier).startSwitchingViaLogout();

      // Remove push subscription for logged out user
      await ref.read(pushSubscriptionSyncProvider.notifier).deletePushSubscriptionForCurrentUser();
    }

    final ionIdentity = await ref.read(ionIdentityProvider.future);
    await ionIdentity(username: currentUser).auth.logOut();
  }

  Future<void> setCurrentUser(String identityKeyName) async {
    await ref
        .read(currentIdentityKeyNameStoreProvider.notifier)
        .setCurrentIdentityKeyName(identityKeyName);
  }

  /// Handles switching to an existing account
  /// Returns true if switching was handled, false if the user is new
  Future<bool> handleSwitchingToExistingAccount(
    String targetUsername, {
    List<String>? currentAuthenticatedUsers,
  }) async {
    final authenticatedUsers =
        currentAuthenticatedUsers ?? state.valueOrNull?.authenticatedIdentityKeyNames ?? [];
    final isSwitchingToExistingAccount = authenticatedUsers.contains(targetUsername);

    final currentUser = ref.read(currentIdentityKeyNameSelectorProvider);
    final needsUserChange = currentUser != targetUsername;

    if (!isSwitchingToExistingAccount) {
      if (needsUserChange) {
        await setCurrentUser(targetUsername);
      }
      return false;
    }

    if (needsUserChange) {
      await setCurrentUser(targetUsername);
    }
    ref.read(userSwitchInProgressProvider.notifier).completeSwitching();
    return true;
  }
}

@Riverpod(keepAlive: true)
class CurrentIdentityKeyNameSelector extends _$CurrentIdentityKeyNameSelector {
  @override
  String? build() {
    return null;
  }

  Future<void> setCurrentIdentityKeyName(String? identityKeyName) async {
    state = identityKeyName;
  }
}

@Riverpod(keepAlive: true)
class CurrentPubkeySelector extends _$CurrentPubkeySelector {
  @override
  String? build() {
    listenSelf(_saveState);
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    if (currentIdentityKeyName == null) {
      return null;
    }
    final mainWallet = ref.watch(mainWalletProvider).valueOrNull;
    return mainWallet?.signingKey.publicKey;
  }

  Future<void> _saveState(String? prev, String? next) async {
    // Saving current master pubkey using sharedPreferencesFoundation
    // to be able to read this value in the iOS Notification Service Extension
    final sharedPreferencesFoundation = await ref.read(sharedPreferencesFoundationProvider.future);
    if (prev != null && next == null) {
      await sharedPreferencesFoundation.remove(prev);
    } else if (next != null) {
      await sharedPreferencesFoundation.setString(persistenceKey, next);
    }
  }

  static const persistenceKey = 'current_master_pubkey';
}

@riverpod
bool isCurrentUserSelector(Ref ref, String pubkey) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  return currentPubkey == pubkey;
}

@Riverpod(keepAlive: true)
Stream<Iterable<String>> authenticatedIdentityKeyNamesStream(Ref ref) async* {
  final ionIdentity = await ref.watch(ionIdentityProvider.future);

  yield* ionIdentity.authorizedUsers;
}

@Riverpod(keepAlive: true)
class CurrentIdentityKeyNameStore extends _$CurrentIdentityKeyNameStore {
  static const String _currentIdentityKeyNameKey = 'Auth:currentIdentityKeyName';

  @override
  Future<String?> build() async {
    final localStorage = await ref.watch(localStorageAsyncProvider.future);
    return localStorage.getString(_currentIdentityKeyNameKey);
  }

  Future<void> setCurrentIdentityKeyName(String identityKeyName) async {
    final localStorage = await ref.read(localStorageAsyncProvider.future);
    await localStorage.setString(_currentIdentityKeyNameKey, identityKeyName);

    state = AsyncData(identityKeyName);
  }

  // Save to sharedPreferencesFoundation for iOS Notification Service Extension access
  Future<void> setCurrentIdentityKeyNameForNotificationServiceExtension(
    String identityKeyName,
  ) async {
    final sharedPreferencesFoundation = await ref.read(sharedPreferencesFoundationProvider.future);
    await sharedPreferencesFoundation.setString(_currentIdentityKeyNameKey, identityKeyName);
  }
}

void onLogout(Ref ref, void Function() callback) {
  ref.listen(authProvider.select((state) => state.valueOrNull?.isAuthenticated), (prev, next) {
    if (prev != null && prev == true && next == false) {
      callback();
    }
  });
}

void onUserSwitch(Ref ref, void Function() callback) {
  ref.listen(
    currentIdentityKeyNameSelectorProvider,
    (prev, next) {
      if (prev != null && next != null && prev != next) {
        callback();
      }
    },
    fireImmediately: false,
  );
}

void keepAliveWhenAuthenticated(Ref ref) {
  final keepAlive = ref.keepAlive();
  onLogout(ref, keepAlive.close);
}

void onLogin(Ref ref, void Function() callback) {
  ref.listen<bool?>(authProvider.select((state) => state.valueOrNull?.isAuthenticated),
      (prev, next) {
    if (prev != null && prev == false && next.falseOrValue == true) {
      callback();
    }
  });
}

void keepAliveWhileUnauthenticated(Ref ref) {
  final keepAlive = ref.keepAlive();
  onLogin(ref, keepAlive.close);
}

@freezed
class UserSwitchState with _$UserSwitchState {
  const factory UserSwitchState({
    @Default(false) bool isSwitchingProgress,
    @Default(false) bool isLogoutTriggered,
    @Default(false) bool isShowNotification,
  }) = _UserSwitchState;
}

@Riverpod(keepAlive: true)
class UserSwitchInProgress extends _$UserSwitchInProgress {
  @override
  UserSwitchState build() {
    ref.listen(
      currentIdentityKeyNameSelectorProvider,
      (prev, next) {
        if (prev != null && next != null && prev != next) {
          completeSwitching();
        }

        if (state.isShowNotification) {
          _showPushNotificationAfterSwitching(next);
        }
      },
    );
    return const UserSwitchState();
  }

  void startSwitching() {
    state = state.copyWith(isSwitchingProgress: true);
  }

  void startSwitchingViaLogout() {
    state = state.copyWith(
      isSwitchingProgress: true,
      isLogoutTriggered: true,
    );
  }

  void needToShowPushSwitchNotification() {
    state = state.copyWith(
      isShowNotification: true,
    );
  }

  void completeSwitching() {
    if (state.isLogoutTriggered) {
      state = state.copyWith(isLogoutTriggered: false);
    } else {
      state = state.copyWith(
        isSwitchingProgress: false,
        isLogoutTriggered: false,
      );
    }
  }

  void _showPushNotificationAfterSwitching(String? identityKeyName) {
    state = state.copyWith(isShowNotification: false);
    if (identityKeyName == null) return;

    final userMetadata = ref.read(userMetadataProvider(identityKeyName)).valueOrNull;
    final username = userMetadata?.data.name ?? identityKeyName;

    final context = rootNavigatorKey.currentContext;
    final message =
        (context != null && context.mounted) ? context.i18n.switched_to_username(username) : '';

    ref.read(messageNotificationNotifierProvider.notifier).show(
          MessageNotification(
            message: message,
            icon: Assets.svg.iconCheckSuccess.icon(size: 16.0.s),
          ),
        );
  }
}
