// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/core/providers/init_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/configure_firebase_app_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/notification_response_service.r.dart';
import 'package:ion/app/services/firebase/firebase_messaging_service_provider.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_response_handler_provider.r.g.dart';

@Riverpod(keepAlive: true)
class NotificationResponseHandler extends _$NotificationResponseHandler {
  // Prevents multiple listeners from being added.
  bool _isInitialized = false;
  StreamSubscription<void>? _firebaseNotificationHandler;
  StreamSubscription<void>? _localNotificationHandler;

  @override
  void build() {
    final firebaseAppConfigured = ref.watch(configureFirebaseAppProvider).valueOrNull ?? false;
    if (firebaseAppConfigured && !_isInitialized) {
      _initialize();
    }

    ref.onDispose(() {
      _firebaseNotificationHandler?.cancel();
      _localNotificationHandler?.cancel();
      _isInitialized = false;
    });
  }

  Future<void> _initialize() async {
    _isInitialized = true;

    final firebaseMessagingService = ref.watch(firebaseMessagingServiceProvider);
    final localNotificationsService = await ref.watch(localNotificationsServiceProvider.future);

    // When the app is opened from a terminated state by a notification.
    // iOS only.
    // Notifications are handled there with a Notification Service Extension then passed to FCM SDK.
    final initialFcmNotificationData = await firebaseMessagingService.getInitialMessageData();
    if (initialFcmNotificationData != null) {
      _handleInitialPushData(initialFcmNotificationData);
    }

    // When the app is opened from a terminated state by a notification.
    // Android only.
    // Notifications are handled there with a background service and presented via local notifications.
    final initialLocalNotificationData =
        await localNotificationsService.getInitialNotificationData();
    if (initialLocalNotificationData != null) {
      _handleInitialPushData(initialLocalNotificationData);
    }

    // if the app is opened from a background state (not terminated) by pressing an FCM notification.
    _firebaseNotificationHandler =
        firebaseMessagingService.onMessageOpenedApp().listen(_handlePushData);

    // if the app is opened from a background state (not terminated) by pressing an local notification.
    _localNotificationHandler =
        localNotificationsService.notificationResponseStream.listen(_handlePushData);
  }

  void _handlePushData(Map<String, dynamic> data) {
    ref.read(notificationResponseServiceProvider).handleNotificationResponse(data);
  }

  void _handleInitialPushData(Map<String, dynamic> data) {
    // Wait for splash animation to complete before handling push notification
    final subscription = ref.listen(splashProvider, (prev, animationCompleted) async {
      if (animationCompleted) {
        final isInitCompleted = ref.read(initAppProvider).hasValue;
        if (!isInitCompleted) {
          await ref.read(initAppProvider.future);
        }

        unawaited(ref.read(notificationResponseServiceProvider).handleNotificationResponse(data));
      }
    });
    ref.onDispose(subscription.close);
  }
}
