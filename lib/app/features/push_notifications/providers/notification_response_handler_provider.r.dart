// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:ion/app/features/push_notifications/providers/configure_firebase_app_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/initial_notification_provider.r.dart';
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
    _listenToFirebaseConfigChanges();

    ref.onDispose(() {
      _firebaseNotificationHandler?.cancel();
      _localNotificationHandler?.cancel();
      _isInitialized = false;
    });
  }

  void _listenToFirebaseConfigChanges() {
    ref.listen(
      configureFirebaseAppProvider,
      (previous, next) {
        final firebaseAppConfigured = next.valueOrNull ?? false;

        if (firebaseAppConfigured && !_isInitialized) {
          _initialize();
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _initialize() async {
    _isInitialized = true;

    final firebaseMessagingService = ref.watch(firebaseMessagingServiceProvider);
    final localNotificationsService = await ref.watch(localNotificationsServiceProvider.future);

    // When the app is opened from a terminated state by a notification.
    Map<String, dynamic>? initialNotificationData;
    if (Platform.isIOS) {
      // Notifications are handled there with a Notification Service Extension then passed to FCM SDK.
      initialNotificationData = await firebaseMessagingService.getInitialMessageData();
    } else if (Platform.isAndroid) {
      // Notifications are handled there with a background service and presented via local notifications.
      initialNotificationData = await localNotificationsService.getInitialNotificationData();
    }

    if (initialNotificationData != null) {
      ref.read(initialNotificationProvider.notifier).notification = initialNotificationData;
    }

    // if the app is opened from a background state (not terminated) by pressing an FCM notification.
    _firebaseNotificationHandler =
        firebaseMessagingService.onMessageOpenedApp().listen(_handlePushData);

    // if the app is opened from a background state (not terminated) by pressing an local notification.
    _localNotificationHandler =
        localNotificationsService.notificationResponseStream.listen(_handlePushData);
  }

  void _handlePushData(Map<String, dynamic> data) {
    ref
        .read(notificationResponseServiceProvider)
        .handleNotificationResponse(data, isInitialNotification: false);
  }
}
