// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/disliked_relay_urls_collection.f.dart';
import 'package:ion/app/features/ion_connect/model/relay_info.f.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_info_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/current_user_write_relay.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_firebase_app_config_provider.m.freezed.dart';
part 'relay_firebase_app_config_provider.m.g.dart';

@Riverpod(keepAlive: true)
class RelayFirebaseAppConfig extends _$RelayFirebaseAppConfig {
  @override
  Future<RelayFirebaseConfig?> build() async {
    final authState = await ref.watch(authProvider.future);
    if (!authState.isAuthenticated) {
      return null;
    }

    final userRelays = await ref.watch(currentUserIdentityConnectRelaysProvider.future);
    if (userRelays == null) {
      return null;
    }

    final savedConfig = ref.watch(savedRelayFirebaseAppConfigProvider);

    // Using a Firebase config from the current write relay, as it is responsible
    // for processing sent events (including push notifications) from this app.
    final writeRelay = ref.watch(currentUserWriteRelayProvider);

    final relayUrls = [for (final userRelay in userRelays) userRelay.url];

    // Using cached firebase config when we're sure it is suitable.
    if (savedConfig != null &&
        relayUrls.contains(savedConfig.relayUrl) &&
        (writeRelay == null || writeRelay == savedConfig.relayUrl)) {
      return savedConfig;
    }

    // Using [writeRelay] with priority because it holds the actual relay
    // that was used to sent the last event.
    // Note: [writeRelay] could even be a read relay fallback if all write relays are unavailable.
    if (writeRelay != null) {
      final relayFirebaseConfig = await _getRelayFirebaseConfig(writeRelay);
      if (relayFirebaseConfig != null) {
        return relayFirebaseConfig;
      }
    }
    // Fresh app start: no write relay is determined yet.
    // We pick a write relay from the user relays pool that possesses a firebase config.
    else {
      final actionSourceRelay = ref.watch(relayPickerProvider.notifier);
      final noFirebaseConfigRelays = <String>{};

      // Continue until we've checked all relays or found a suitable one
      while (userRelays.length > noFirebaseConfigRelays.length) {
        final relay = await actionSourceRelay.getActionSourceRelays(
          const ActionSourceCurrentUser(),
          actionType: ActionType.write,
          dislikedUrls: DislikedRelayUrlsCollection(noFirebaseConfigRelays),
        );
        final relayUrl = relay.keys.first.url;

        final relayFirebaseConfig = await _getRelayFirebaseConfig(relayUrl);
        if (relayFirebaseConfig != null) {
          return relayFirebaseConfig;
        } else {
          // Remember relays without Firebase support to avoid retrying
          noFirebaseConfigRelays.add(relayUrl);
        }
      }
    }

    return null;
  }

  Future<RelayFirebaseConfig?> _getRelayFirebaseConfig(String relayUrl) async {
    final relayInfo = await ref.watch(relayInfoProvider(relayUrl).future);
    final relayPubkey = relayInfo.pubkey;
    final firebaseConfigs = relayInfo.getFirebaseConfigsForPlatform();
    if (firebaseConfigs == null || relayPubkey == null || relayPubkey.isEmpty) {
      return null;
    }

    final randomFirebaseConfig = firebaseConfigs.random;

    if (randomFirebaseConfig == null) {
      return null;
    }

    return RelayFirebaseConfig(
      firebaseConfig: randomFirebaseConfig,
      relayUrl: relayUrl,
      relayPubkey: relayPubkey,
    );
  }
}

@Riverpod(keepAlive: true)
class SavedRelayFirebaseAppConfig extends _$SavedRelayFirebaseAppConfig {
  @override
  RelayFirebaseConfig? build() {
    return _loadConfig();
  }

  set config(RelayFirebaseConfig config) {
    state = config;
    _saveConfig(config);
  }

  Future<void> _saveConfig(RelayFirebaseConfig? relayFirebaseConfig) async {
    if (relayFirebaseConfig == null) {
      await ref.read(localStorageProvider).remove(_configuredFirebaseAppKey);
    } else {
      await ref.read(localStorageProvider).setString(
            _configuredFirebaseAppKey,
            jsonEncode(relayFirebaseConfig.toJson()),
          );
    }
  }

  RelayFirebaseConfig? _loadConfig() {
    try {
      final relayFirebaseConfigJson =
          ref.read(localStorageProvider).getString(_configuredFirebaseAppKey);
      if (relayFirebaseConfigJson == null) {
        return null;
      }
      return RelayFirebaseConfig.fromJson(
        jsonDecode(relayFirebaseConfigJson) as Map<String, dynamic>,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to load configured Firebase app',
      );
      return null;
    }
  }

  static const String _configuredFirebaseAppKey = 'configured_firebase_app_key';
}

@riverpod
class BuildInFirebaseAppConfig extends _$BuildInFirebaseAppConfig {
  @override
  FirebaseConfig? build() {
    try {
      final env = ref.read(envProvider.notifier);
      return FirebaseConfig.fromJson(
        jsonDecode(env.get<String>(EnvVariable.FIREBASE_CONFIG)) as Map<String, dynamic>,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to load build-in Firebase app',
      );
      return null;
    }
  }
}

@freezed
class RelayFirebaseConfig with _$RelayFirebaseConfig {
  const factory RelayFirebaseConfig({
    required String relayUrl,
    required String relayPubkey,
    required FirebaseConfig firebaseConfig,
  }) = _RelayFirebaseConfig;

  factory RelayFirebaseConfig.fromJson(Map<String, dynamic> json) =>
      _$RelayFirebaseConfigFromJson(json);
}
