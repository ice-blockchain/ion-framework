// SPDX-License-Identifier: ice License 1.0

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'facebook_conversion_tracking_service.r.g.dart';

@Riverpod(keepAlive: true)
class FacebookConversionTrackingService extends _$FacebookConversionTrackingService {
  @override
  Future<void> build() async {
    try {
      // FacebookAppEvents reads App ID and Client Token from platform configuration files
      // (Info.plist for iOS, AndroidManifest.xml for Android)
      // The SDK automatically initializes on app launch and tracks install conversions
      // on first launch when App ID and Client Token are properly configured.
      // No manual initialization needed - install attribution happens automatically.

      // Create instance to ensure SDK is initialized
      // The SDK will read configuration from platform files automatically

      FacebookAppEvents();

      Logger.log('Facebook conversion tracking initialized successfully');
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to initialize Facebook conversion tracking: $error',
      );
    }
  }
}
