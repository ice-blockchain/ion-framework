// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_notifications.r.g.dart';

class LocalNotificationsService {
  LocalNotificationsService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  final _notificationResponseController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationResponseStream =>
      _notificationResponseController.stream;

  Future<void> initialize() async {
    await _plugin.initialize(
      _settings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null) {
          _notificationResponseController.sink.add(
            jsonDecode(payload) as Map<String, dynamic>,
          );
        }
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? iconFilePath,
    String? attachmentFilePath,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      _notificationDetails(
        iconFilePath: iconFilePath,
        attachmentFilePath: attachmentFilePath,
      ),
      payload: payload,
    );
  }

  Future<Map<String, dynamic>?> getInitialNotificationData() async {
    final initialNotification = await _plugin.getNotificationAppLaunchDetails();
    final payload = initialNotification?.notificationResponse?.payload;
    return payload != null ? jsonDecode(payload) as Map<String, dynamic> : null;
  }

  static InitializationSettings get _settings {
    const initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_ic_notification');
    // Do not request permissions on iOS when the plugin is initialized
    // We do that manually either during the onboarding or in the app settings
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: false,
      defaultPresentBadge: false,
      defaultPresentSound: false,
    );
    return const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );
  }

  static NotificationDetails _notificationDetails({
    String? iconFilePath,
    String? attachmentFilePath,
  }) {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'ion_miscellaneous',
      'Miscellaneous',
      color: const Color(0xFF0166FF),
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: iconFilePath != null ? DrawableResourceAndroidBitmap(iconFilePath) : null,
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    return NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }
}

@Riverpod(keepAlive: true)
Future<LocalNotificationsService> localNotificationsService(Ref ref) async {
  final service = LocalNotificationsService();
  await service.initialize();
  return service;
}
