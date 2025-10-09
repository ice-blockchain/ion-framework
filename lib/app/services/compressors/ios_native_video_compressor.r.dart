// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/media_service/video_info_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ios_native_video_compressor.r.g.dart';

class IosNativeVideoCompressionSettings {
  const IosNativeVideoCompressionSettings({
    required this.height,
    required this.quality,
    required this.realtime,
  });

  static const int defaultMaxDimension = 1080;

  static const balanced = IosNativeVideoCompressionSettings(
    quality: 0.75,
    height: defaultMaxDimension,
    realtime: true,
  );

  final int height;
  final double quality; // 0.0 - 1.0, where 1.0 is highest quality (VBR encoding)
  final bool realtime; // expectsMediaDataInRealTime parameter
}

class IosNativeVideoCompressor implements Compressor<IosNativeVideoCompressionSettings> {
  IosNativeVideoCompressor({
    required this.videoInfoService,
  });

  final VideoInfoService videoInfoService;

  static const MethodChannel _channel = MethodChannel('ion/video_compression');

  @override
  Future<MediaFile> compress(
    MediaFile file, {
    IosNativeVideoCompressionSettings? settings,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final originalFile = File(file.path);
      final originalSize = await originalFile.length();

      Logger.log('Original video size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      final output = await generateOutputPath(extension: 'mp4');

      final (
        width: originalWidth,
        height: originalHeight,
        duration: originalDuration,
        bitrate: originalBitrate
      ) = await videoInfoService.getVideoInformation(file.path);
      Logger.log('Original dimensions: ${originalWidth}x$originalHeight');
      if (originalBitrate != null) {
        Logger.log('Original bitrate: ${(originalBitrate / 1000000).toStringAsFixed(2)} Mbps');
      }

      final targetDimensions = _calculateTargetDimensions(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        maxDimension: settings?.height ?? IosNativeVideoCompressionSettings.defaultMaxDimension,
      );

      Logger.log('Target dimensions: ${targetDimensions.width}x${targetDimensions.height}');

      Logger.log(
        'Time since start: ${stopwatch.elapsed.inSeconds}.${stopwatch.elapsed.inMilliseconds % 1000}s',
      );

      await _channel.invokeMethod('compressVideo', {
        'inputPath': file.path,
        'outputPath': output,
        'destWidth': targetDimensions.width,
        'destHeight': targetDimensions.height,
        'codec': 'hevc',
        'quality': settings?.quality,
        'realtime': false,
      });

      final compressedFile = File(output);
      final compressedSize = await compressedFile.length();

      Logger.log(
        'Compressed video size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      Logger.log(
        'Compression time: ${stopwatch.elapsed.inSeconds}.${stopwatch.elapsed.inMilliseconds % 1000}s',
      );

      return MediaFile(
        path: output,
        mimeType: MimeType.video.value,
        originalMimeType: file.originalMimeType,
        name: file.name,
        width: targetDimensions.width,
        height: targetDimensions.height,
        duration: originalDuration.inSeconds,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  ({int width, int height}) _calculateTargetDimensions({
    required int originalWidth,
    required int originalHeight,
    required int maxDimension,
  }) {
    if (originalWidth <= maxDimension && originalHeight <= maxDimension) {
      return (width: originalWidth, height: originalHeight);
    }

    final aspectRatio = originalWidth / originalHeight;

    int targetWidth;
    int targetHeight;

    if (originalWidth > originalHeight) {
      targetWidth = maxDimension;
      targetHeight = (maxDimension / aspectRatio).round();
    } else {
      targetHeight = maxDimension;
      targetWidth = (maxDimension * aspectRatio).round();
    }

    targetWidth = (targetWidth ~/ 2) * 2;
    targetHeight = (targetHeight ~/ 2) * 2;

    return (width: targetWidth, height: targetHeight);
  }
}

@Riverpod(keepAlive: true)
IosNativeVideoCompressor iosNativeVideoCompressor(Ref ref) => IosNativeVideoCompressor(
      videoInfoService: ref.read(videoInfoServiceProvider),
    );
