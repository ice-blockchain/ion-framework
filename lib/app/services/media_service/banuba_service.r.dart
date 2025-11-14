// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_video_playback_enabled.r.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/url.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uri_to_file/uri_to_file.dart';

part 'banuba_service.r.g.dart';

typedef EditVideResult = ({String newPath, String? thumb});

class BanubaService {
  const BanubaService(this.env, this.feedVideoPlaybackEnabledNotifier);

  final Env env;
  final FeedVideoPlaybackEnabledNotifier feedVideoPlaybackEnabledNotifier;
  // For Photo Editor
  static const methodInitPhotoEditor = 'initPhotoEditor';
  static const methodStartPhotoEditor = 'startPhotoEditor';
  static const argExportedPhotoFile = 'argExportedPhotoFilePath';

  // For Video Editor
  static const methodInitVideoEditor = 'initVideoEditor';
  static const methodStartVideoEditor = 'startVideoEditor';
  static const methodStartVideoEditorTrimmer = 'startVideoEditorTrimmer';
  static const argVideoFilePath = 'videoFilePath';
  static const argMaxVideoDurationMs = 'maxVideoDurationMs';
  static const argCoverSelectionEnabled = 'coverSelectionEnabled';
  static const argExportedVideoFile = 'argExportedVideoFilePath';
  static const argExportedVideoCoverPreview = 'argExportedVideoCoverPreviewPath';
  static const methodReleaseVideoEditor = 'releaseVideoEditor';

  static const platformChannel = MethodChannel('banubaSdkChannel');

  Future<void> _initPhotoEditor() async {
    if (Platform.isAndroid) {
      await platformChannel.invokeMethod(methodReleaseVideoEditor);
    }

    await platformChannel.invokeMethod(
      methodInitPhotoEditor,
      env.get<String>(EnvVariable.BANUBA_TOKEN),
    );
  }

  Future<String?> editPhoto(String filePath) async {
    try {
      await _initPhotoEditor();

      final dynamic result = await platformChannel.invokeMethod(
        methodStartPhotoEditor,
        {'imagePath': filePath},
      );

      if (result is Map) {
        final exportedPhotoFilePath = result[argExportedPhotoFile];

        if (exportedPhotoFilePath == null) {
          return null;
        }

        if (Platform.isAndroid) {
          final file = await toFile(exportedPhotoFilePath as String);
          return file.path;
        }

        return exportedPhotoFilePath as String;
      }
      return null;
    } on PlatformException catch (e) {
      Logger.log(
        'Start Photo Editor error',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  Future<EditVideResult?> editVideo(
    String filePath, {
    Duration? maxVideoDuration = const Duration(seconds: 60),
    bool coverSelectionEnabled = true,
  }) async {
    feedVideoPlaybackEnabledNotifier.disablePlayback();
    await platformChannel.invokeMethod(
      methodInitVideoEditor,
      env.get<String>(EnvVariable.BANUBA_TOKEN),
    );

    final result = await platformChannel.invokeMethod(
      methodStartVideoEditorTrimmer,
      {
        argVideoFilePath: filePath,
        argMaxVideoDurationMs: maxVideoDuration?.inMilliseconds,
        argCoverSelectionEnabled: coverSelectionEnabled,
      },
    );
    feedVideoPlaybackEnabledNotifier.enablePlayback();

    if (result is Map) {
      var newPath = result[argExportedVideoFile] as String;
      var thumb = result[argExportedVideoCoverPreview] as String;

      // Convert file:// URIs to file paths on Android
      if (Platform.isAndroid) {
        newPath = fileUriToPath(newPath);
        thumb = fileUriToPath(thumb);
      }

      return (newPath: newPath, thumb: thumb);
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
BanubaService banubaService(Ref ref) {
  return BanubaService(
    ref.watch(envProvider.notifier),
    ref.watch(feedVideoPlaybackEnabledNotifierProvider.notifier),
  );
}

@riverpod
Future<MediaFile?> editMedia(
  Ref ref,
  MediaFile mediaFile, {
  Duration? maxVideoDuration,
  bool videoCoverSelectionEnabled = true,
}) async {
  final filePath = path.isAbsolute(mediaFile.path)
      ? mediaFile.path
      : await ref.read(assetFilePathProvider(mediaFile.path).future);

  if (filePath == null) {
    Logger.log(
      'File path or mime type is null',
      error: mediaFile,
      stackTrace: StackTrace.current,
    );
    throw AssetEntityFileNotFoundException();
  }

  if (mediaFile.mimeType == null) {
    Logger.log(
      'Mime type is null',
      error: mediaFile,
      stackTrace: StackTrace.current,
    );
    throw AssetEntityFileNotFoundException();
  }

  final mediaType = MediaType.fromMimeType(mediaFile.mimeType!);

  switch (mediaType) {
    case MediaType.image:
      final newPath = await ref.read(banubaServiceProvider).editPhoto(filePath);
      if (newPath == null) return null;
      return mediaFile.copyWith(path: newPath);
    case MediaType.video:
      final editVideoData = await ref.read(banubaServiceProvider).editVideo(
            filePath,
            maxVideoDuration: maxVideoDuration,
            coverSelectionEnabled: videoCoverSelectionEnabled,
          );
      if (editVideoData == null) return null;
      return mediaFile.copyWith(path: editVideoData.newPath, thumb: editVideoData.thumb);
    case MediaType.unknown || MediaType.audio:
      throw Exception('Unknown media type');
  }
}
