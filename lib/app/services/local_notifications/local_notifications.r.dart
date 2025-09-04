// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/converters/dart_webp_to_jpeg_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/uuid/uuid.dart';
import 'package:ion/app/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
    required String title,
    required String body,
    String? payload,
    String? icon,
    String? attachment,
  }) async {
    final notificationDetails = await _buildNotificationDetails(
      avatarUrl: icon,
      attachmentUrl: attachment,
      userName: title,
      textMessage: body,
    );

    await _plugin.show(
      generateUuid().hashCode,
      title,
      body,
      notificationDetails,
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

  Future<NotificationDetails> _buildNotificationDetails({
    String? avatarUrl,
    String? attachmentUrl,
    String? userName,
    String? textMessage,
  }) async {
    Person? messagePerson;
    String? avatarFilePath;

    if (avatarUrl != null) {
      avatarFilePath = await _getMediaFilePath(Uri.parse(avatarUrl), storeToCache: true);
    }

    messagePerson = Person(
      key: userName,
      name: userName,
      icon: avatarFilePath != null ? BitmapFilePathAndroidIcon(avatarFilePath) : null,
    );

    String? attachmentFilePath;
    if (attachmentUrl != null) {
      attachmentFilePath = await _getMediaFilePath(Uri.parse(attachmentUrl));
    }

    StyleInformation? styleInformation;
    styleInformation = MessagingStyleInformation(
      messagePerson,
      groupConversation: false,
      messages: [
        Message(
          textMessage ?? '',
          DateTime.now(),
          messagePerson,
          dataMimeType: attachmentFilePath != null ? ImageCompressionType.jpeg.mimeType : null,
          dataUri: attachmentFilePath,
        ),
      ],
    );

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'ion_miscellaneous',
      'Miscellaneous',
      color: AppColorsExtension.defaultColors().primaryAccent,
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: attachmentFilePath != null ? FilePathAndroidBitmap(attachmentFilePath) : null,
      styleInformation: styleInformation,
      shortcutId: const Uuid().v4(),
    );

    final iOSPerson = DarwinCommunicationPerson(
      handle: userName ?? 'unknown_user',
      displayName: userName,
      avatarFilePath: avatarFilePath,
    );

    final iOSPlatformChannelSpecifics = DarwinCommunicationNotificationDetails(
      conversationIdentifier: userName ?? 'ion_miscellaneous',
      messages: [
        DarwinCommunicationMessage(
          text: textMessage ?? '',
          sender: iOSPerson,
          dateSent: DateTime.now(),
          attachmentFilePath: attachmentFilePath,
        ),
      ],
      attachments:
          attachmentFilePath != null ? [DarwinNotificationAttachment(attachmentFilePath)] : [],
    );

    return NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }

  Future<String?> _getMediaFilePath(Uri uri, {bool storeToCache = false}) async {
    try {
      final directory = await getTemporaryDirectory();

      final compressionTypeName = ImageCompressionType.jpeg.name;

      final urlHash = uri.hashCode.abs().toString();
      final cachedFileName = '${urlHash}_compressed.$compressionTypeName';
      final cachedFilePath = '${directory.path}/$cachedFileName';

      final originalFileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'image';
      final originalExtension =
          originalFileName.contains('.') ? originalFileName.split('.').last : compressionTypeName;

      final cachedFile = File(cachedFilePath);
      final cachedFileExists = cachedFile.existsSync();
      if (cachedFileExists) {
        Logger.log('Using cached media file: $cachedFilePath');
        return cachedFilePath;
      }

      List<int>? data;

      if (uri.scheme == 'file' || (!uri.hasScheme && uri.path.isNotEmpty)) {
        String localFilePath;
        if (uri.hasScheme) {
          localFilePath = uri.toFilePath();
        } else {
          localFilePath = Uri.decodeComponent(uri.path);
        }

        final localFile = File(localFilePath);
        if (!localFile.existsSync()) {
          return null;
        }

        data = await localFile.readAsBytes();
      } else {
        data = await _downloadFile(uri);
      }

      if (data == null) {
        return null;
      }

      final tempFileName = '${urlHash}_temp.$originalExtension';
      final tempFilePath = '${directory.path}/$tempFileName';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(data);

      // Need to convert from webp to jpeg since conversations push notifications not support webp
      final convertedMedia = await webpToJpeg(tempFilePath);

      final compressedFile = File(convertedMedia.path);

      if (tempFile.existsSync()) {
        await tempFile.delete();
      }

      if (storeToCache) {
        await compressedFile.copy(cachedFilePath);

        if (convertedMedia.path != cachedFilePath && compressedFile.existsSync()) {
          await compressedFile.delete();
        }

        Logger.log('Media file cached: $cachedFilePath');
        return cachedFilePath;
      } else {
        Logger.log('Media file processed without caching: ${convertedMedia.path}');
        return convertedMedia.path;
      }
    } catch (e) {
      Logger.log('Error processing media file: $e');
      return null;
    }
  }

  Future<List<int>?> _downloadFile(Uri uri) async {
    try {
      final response = await Dio().getUri<List<int>>(
        uri,
        options: Options(responseType: ResponseType.bytes),
      );

      return response.data;
    } catch (e) {
      Logger.log('Failed to download file: $e');
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
Future<LocalNotificationsService> localNotificationsService(Ref ref) async {
  final service = LocalNotificationsService();
  await service.initialize();
  return service;
}
