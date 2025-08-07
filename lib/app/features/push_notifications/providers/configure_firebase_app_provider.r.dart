// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/relay_info.f.dart';
import 'package:ion/app/features/push_notifications/providers/relay_firebase_app_config_provider.m.dart';
import 'package:ion/app/services/firebase/firebase_messaging_service_provider.r.dart';
import 'package:ion/app/services/firebase/firebase_service_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'configure_firebase_app_provider.r.g.dart';

@Riverpod(keepAlive: true)
class ConfigureFirebaseApp extends _$ConfigureFirebaseApp {
  @override
  Future<bool> build() async {
    final firebaseAppService = ref.watch(firebaseAppServiceProvider);
    final savedRelayFirebaseAppConfig = ref.watch(savedRelayFirebaseAppConfigProvider);
    final buildInFirebaseAppConfig = ref.watch(buildInFirebaseAppConfigProvider);

    if (!firebaseAppService.hasApp()) {
      if (buildInFirebaseAppConfig != null) {
        // Always initialize the built-in config first.
        // If it exists in the app, we must initialize it before adding another config.
        // Deleting the built-in config also requires it to be initialized first.
        await _initializeFirebaseApp(buildInFirebaseAppConfig);
      } else if (savedRelayFirebaseAppConfig != null) {
        // Initialize the previously configured app if the built-in config is unavailable.
        // This ensures we can properly delete it later if reconfiguration is needed,
        // for example, when the currently configured relay is no longer accessible.
        await _initializeFirebaseApp(savedRelayFirebaseAppConfig.firebaseConfig);
      }
    }

    final relayFirebaseAppConfig = await ref.watch(relayFirebaseAppConfigProvider.future);

    if (relayFirebaseAppConfig != null) {
      final initialized = await _initializeFirebaseApp(
        relayFirebaseAppConfig.firebaseConfig,
        // if we had some previously configured firebase app,
        // and now we need a new one, we also need to reset the prev app fcm token
        resetPrevFcmToken: savedRelayFirebaseAppConfig != null,
      );
      if (initialized) {
        ref.read(savedRelayFirebaseAppConfigProvider.notifier).config = relayFirebaseAppConfig;
        return true;
      }
    }

    return false;
  }

  Future<bool> _initializeFirebaseApp(
    FirebaseConfig firebaseConfig, {
    bool resetPrevFcmToken = false,
  }) async {
    if (_currentFirebaseConfig == firebaseConfig) {
      return true;
    }

    try {
      final firebaseAppService = ref.watch(firebaseAppServiceProvider);
      final firebaseMessagingService = ref.watch(firebaseMessagingServiceProvider);

      if (firebaseAppService.hasApp()) {
        if (resetPrevFcmToken) {
          // Without revoking the fcm token, the app will still receive notifications from the deleted app.
          await firebaseMessagingService.deleteToken();
        }
        await firebaseAppService.deleteApp();
      }

      await firebaseAppService.initializeApp(
        FirebaseAppOptions(
          apiKey: firebaseConfig.apiKey,
          appId: firebaseConfig.appId,
          messagingSenderId: firebaseConfig.messagingSenderId,
          projectId: firebaseConfig.projectId,
        ),
      );

      _currentFirebaseConfig = firebaseConfig;

      return true;
    } catch (error) {
      return false;
    }
  }

  FirebaseConfig? _currentFirebaseConfig;
}
