// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/compressors/compress_executor.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/uuid/uuid.dart';
import 'package:ion/app/theme/app_colors.dart';
import 'package:ion/generated/assets.gen.dart';
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
    String? iconFilePath,
    String? attachmentFilePath,
    bool isConversationPush = false,
  }) async {
    await _plugin.show(
      generateUuid().hashCode,
      title,
      body,
      isConversationPush
          ? await _messageNotificationDetails(
              avatarUrl: iconFilePath,
              attachmentUrl: attachmentFilePath,
              userName: title,
              textMessage: body,
            )
          : _defaultNotificationDetails,
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

  Future<NotificationDetails> _messageNotificationDetails({
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

    // Use fallback avatar if no avatar URL provided or if processing failed
    avatarFilePath ??= await _copyAssetToTempFile(Assets.images.iconProfileNoimage.path);

    if (avatarFilePath != null) {
      messagePerson = Person(
        key: userName,
        name: userName,
        icon: BitmapFilePathAndroidIcon(avatarFilePath),
      );
    }

    String? attachmentFilePath;
    if (attachmentUrl != null) {
      attachmentFilePath = await _getMediaFilePath(Uri.parse(attachmentUrl));
    }

    StyleInformation? styleInformation;
    if (messagePerson != null) {
      styleInformation = MessagingStyleInformation(
        messagePerson,
        groupConversation: false,
        messages: [
          Message(
            textMessage ?? '',
            DateTime.now(),
            messagePerson,
            dataMimeType: attachmentFilePath != null ? 'image/jpg' : null,
            dataUri: attachmentFilePath,
          ),
        ],
      );
    }

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'ion_miscellaneous',
      'Miscellaneous',
      color: AppColorsExtension.defaultColors().primaryAccent,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: styleInformation,
      shortcutId: const Uuid().v4(),
    );

    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    return NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }

  Future<String?> _getMediaFilePath(Uri uri, {bool storeToCache = false}) async {
    try {
      final directory = await getTemporaryDirectory();

      final urlHash = uri.hashCode.abs().toString();
      final cachedFileName = '${urlHash}_compressed.jpg';
      final cachedFilePath = '${directory.path}/$cachedFileName';

      final originalFileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'image';
      final originalExtension =
          originalFileName.contains('.') ? originalFileName.split('.').last : 'jpg';

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

      // Need to compress from webp to jpg since conversations push notifications not support webp
      final compressor = ImageCompressor(compressExecutor: CompressExecutor());
      final compressedMedia = await compressor.compress(
        MediaFile(path: tempFilePath),
        to: ImageCompressionType.jpg,
      );

      final compressedFile = File(compressedMedia.path);

      if (tempFile.existsSync()) {
        await tempFile.delete();
      }

      if (storeToCache) {
        await compressedFile.copy(cachedFilePath);

        if (compressedMedia.path != cachedFilePath && compressedFile.existsSync()) {
          await compressedFile.delete();
        }

        Logger.log('Media file cached: $cachedFilePath');
        return cachedFilePath;
      } else {
        Logger.log('Media file processed without caching: ${compressedMedia.path}');
        return compressedMedia.path;
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

  Future<String?> _copyAssetToTempFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final fileName = 'fallback_avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${directory.path}/$fileName');

      await tempFile.writeAsBytes(bytes);

      Logger.log('Copied asset to temp file: ${tempFile.path}');
      return tempFile.path;
    } catch (e) {
      Logger.log('Failed to copy asset to temp file: $e');
      return null;
    }
  }
}

NotificationDetails get _defaultNotificationDetails {
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'ion_miscellaneous',
    'Miscellaneous',
    color: AppColorsExtension.defaultColors().primaryAccent,
    importance: Importance.max,
    priority: Priority.high,
  );
  const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
  return NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );
}

@Riverpod(keepAlive: true)
Future<LocalNotificationsService> localNotificationsService(Ref ref) async {
  final service = LocalNotificationsService();
  await service.initialize();
  return service;
}
