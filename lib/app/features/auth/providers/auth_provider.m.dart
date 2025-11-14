// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/bool.dart';
import 'package:ion/app/features/auth/providers/local_passkey_creds_provider.r.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/user/providers/biometrics_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.m.freezed.dart';
part 'auth_provider.m.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required List<String> authenticatedIdentityKeyNames,
    required String? currentIdentityKeyName,
    required bool suggestToAddBiometrics,
    required bool suggestToCreateLocalPasskeyCreds,
    required bool hasEventSigner,
  }) = _AuthState;

  const AuthState._();

  bool get isAuthenticated {
    return currentIdentityKeyName != null &&
        authenticatedIdentityKeyNames.contains(currentIdentityKeyName) &&
        !suggestToAddBiometrics &&
        !suggestToCreateLocalPasskeyCreds &&
        hasEventSigner;
  }
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  bool _isNewUserFlowActive = false;
  int _usersCountAtNewUserFlowStart = 0;

  @override
  Future<AuthState> build() async {
    final authenticatedIdentityKeyNames =
        await ref.watch(authenticatedIdentityKeyNamesStreamProvider.future);

    final savedIdentityKeyName = await ref.watch(currentIdentityKeyNameStoreProvider.future);

    final isWaitingForNewUser = _isNewUserFlowActive &&
        _usersCountAtNewUserFlowStart == authenticatedIdentityKeyNames.length;

    final currentIdentityKeyName = isWaitingForNewUser
        ? null
        : _determineCurrentUser(authenticatedIdentityKeyNames, savedIdentityKeyName);

    final biometricsStates = await ref.watch(biometricsStatesStreamProvider.future);
    final localPasskeyCredsStates = await ref.watch(localPasskeyCredsStatesStreamProvider.future);
    final userBiometricsState = _getUserBiometricsState(currentIdentityKeyName, biometricsStates);
    final userLocalPasskeyCredsState = _getUserLocalPasskeyCredsState(
      currentIdentityKeyName,
      localPasskeyCredsStates,
    );

    final eventSigner = await _initializeEventSigner(currentIdentityKeyName);
    _syncCurrentUserToStorages(currentIdentityKeyName);
    _setupLogoutListener();

    return AuthState(
      currentIdentityKeyName: currentIdentityKeyName,
      authenticatedIdentityKeyNames: authenticatedIdentityKeyNames.toList(),
      suggestToAddBiometrics: userBiometricsState == BiometricsState.canSuggest,
      suggestToCreateLocalPasskeyCreds:
          userLocalPasskeyCredsState == LocalPasskeyCredsState.canSuggest,
      hasEventSigner: eventSigner != null,
    );
  }

  String? _determineCurrentUser(
    Iterable<String> authenticatedIdentityKeyNames,
    String? savedIdentityKeyName,
  ) {
    _isNewUserFlowActive = false;

    if (authenticatedIdentityKeyNames.contains(savedIdentityKeyName)) {
      return savedIdentityKeyName;
    }

    return authenticatedIdentityKeyNames.lastOrNull;
  }

  BiometricsState? _getUserBiometricsState(
    String? currentIdentityKeyName,
    Map<String, BiometricsState> biometricsStates,
  ) {
    if (currentIdentityKeyName == null) return null;

    return biometricsStates[currentIdentityKeyName];
  }

  LocalPasskeyCredsState? _getUserLocalPasskeyCredsState(
    String? currentIdentityKeyName,
    Map<String, LocalPasskeyCredsState> localPasskeyCredsStates,
  ) {
    if (currentIdentityKeyName == null) return null;

    return localPasskeyCredsStates[currentIdentityKeyName];
  }

  Future<dynamic> _initializeEventSigner(String? currentIdentityKeyName) async {
    if (currentIdentityKeyName == null) return null;

    return ref
        .watch(ionConnectEventSignerProvider(currentIdentityKeyName).notifier)
        .initEventSigner();
  }

  void _syncCurrentUserToStorages(String? currentIdentityKeyName) {
    if (currentIdentityKeyName == null) {
      return;
    }

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

  void _setupLogoutListener() {
    listenSelf((_, next) async {
      final authenticatedUsers = next.valueOrNull?.authenticatedIdentityKeyNames;
      if (authenticatedUsers == null || authenticatedUsers.isEmpty) {
        await Future<void>.delayed(const Duration(seconds: 1));
        unawaited(
          ref.read(currentIdentityKeyNameSelectorProvider.notifier).setCurrentIdentityKeyName(null),
        );
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    final currentUser = ref.read(currentIdentityKeyNameSelectorProvider);
    if (currentUser == null) {
      return;
    }

    ref.read(userSwitchProvider.notifier).trigger();
    final ionIdentity = await ref.read(ionIdentityProvider.future);
    await ionIdentity(username: currentUser).auth.logOut();
  }

  Future<void> clearCurrentUserForAuthentication() async {
    _isNewUserFlowActive = true;
    _usersCountAtNewUserFlowStart =
        (await ref.read(authenticatedIdentityKeyNamesStreamProvider.future)).length;

    final currentUser = ref.read(currentIdentityKeyNameSelectorProvider);
    if (currentUser != null) {
      ref.read(userSwitchProvider.notifier).trigger();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await ref
          .read(currentIdentityKeyNameSelectorProvider.notifier)
          .setCurrentIdentityKeyName(null);
      await ref.read(currentIdentityKeyNameStoreProvider.notifier).clearCurrentIdentityKeyName();

      ref.invalidateSelf();
    }
  }

  Future<void> setCurrentUser(String identityKeyName) async {
    final currentUser = ref.read(currentIdentityKeyNameSelectorProvider);

    if (currentUser != null && currentUser != identityKeyName) {
      ref.read(userSwitchProvider.notifier).trigger();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    await ref
        .read(currentIdentityKeyNameStoreProvider.notifier)
        .setCurrentIdentityKeyName(identityKeyName);

    await ref
        .read(currentIdentityKeyNameSelectorProvider.notifier)
        .setCurrentIdentityKeyName(identityKeyName);

    await ref
        .read(currentIdentityKeyNameStoreProvider.notifier)
        .setCurrentIdentityKeyNameForNotificationServiceExtension(identityKeyName);

    ref
      ..invalidate(currentPubkeySelectorProvider)
      ..invalidateSelf();
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
  static const String currentIdentityKeyNameKey = 'Auth:currentIdentityKeyName';

  @override
  Future<String?> build() async {
    final localStorage = await ref.watch(localStorageAsyncProvider.future);
    return localStorage.getString(currentIdentityKeyNameKey);
  }

  Future<void> setCurrentIdentityKeyName(String identityKeyName) async {
    final localStorage = await ref.read(localStorageAsyncProvider.future);
    await localStorage.setString(currentIdentityKeyNameKey, identityKeyName);

    state = AsyncData(identityKeyName);
  }

  // Save to sharedPreferencesFoundation for iOS Notification Service Extension access
  Future<void> setCurrentIdentityKeyNameForNotificationServiceExtension(
    String identityKeyName,
  ) async {
    final sharedPreferencesFoundation = await ref.read(sharedPreferencesFoundationProvider.future);
    await sharedPreferencesFoundation.setString(currentIdentityKeyNameKey, identityKeyName);
  }

  Future<void> clearCurrentIdentityKeyName() async {
    final localStorage = await ref.read(localStorageAsyncProvider.future);
    await localStorage.remove(currentIdentityKeyNameKey);

    state = const AsyncData(null);
  }
}

void onLogout(Ref ref, void Function() callback) {
  ref.listen(authProvider.select((state) => state.valueOrNull?.isAuthenticated), (prev, next) {
    if (prev != null && prev == true && next == false) {
      callback();
    }
  });
}

@Riverpod(keepAlive: true)
class UserSwitch extends _$UserSwitch {
  @override
  int build() {
    return 0;
  }

  void trigger() {
    state = state + 1;
  }
}

void onUserSwitch(Ref ref, void Function() callback) {
  ref.listen<int>(
    userSwitchProvider,
    (prev, next) {
      if (prev != null && prev != next) {
        callback();
      }
    },
    fireImmediately: false,
  );
}

void keepAliveWhenAuthenticated(Ref ref) {
  final keepAlive = ref.keepAlive();
  onLogout(ref, keepAlive.close);
  onUserSwitch(ref, keepAlive.close);
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
