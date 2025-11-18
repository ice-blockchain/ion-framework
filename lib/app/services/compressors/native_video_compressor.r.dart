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
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'native_video_compressor.r.g.dart';

class NativeVideoCompressionSettings {
  const NativeVideoCompressionSettings({
    required this.height,
    required this.quality,
    required this.codec,
  });

  static const int defaultMaxDimension = 1080;

  static const balanced = NativeVideoCompressionSettings(
    quality: 0.75,
    height: defaultMaxDimension,
    codec: 'h264',
  );

  final String codec;
  final int height;
  final double quality; // 0.0 - 1.0, where 1.0 is highest quality
}

class AndroidNativeVideoCompressionSettings extends NativeVideoCompressionSettings {
  const AndroidNativeVideoCompressionSettings({
    required super.height,
    required super.quality,
    required super.codec,
  });

  static const balanced = AndroidNativeVideoCompressionSettings(
    quality: 0.75,
    height: NativeVideoCompressionSettings.defaultMaxDimension,
    codec: 'h264',
  );
}

class IosNativeVideoCompressionSettings extends NativeVideoCompressionSettings {
  const IosNativeVideoCompressionSettings({
    required super.height,
    required super.quality,
    required super.codec,
  });

  static const balanced = IosNativeVideoCompressionSettings(
    quality: 0.75,
    height: NativeVideoCompressionSettings.defaultMaxDimension,
    codec: 'hevc',
  );
}

class NativeVideoCompressor implements Compressor<NativeVideoCompressionSettings> {
  NativeVideoCompressor({
    required this.videoInfoService,
  });
  final VideoInfoService videoInfoService;

  static const MethodChannel _channel = MethodChannel('ion/video_compression');

  @override
  Future<MediaFile> compress(
    MediaFile file, {
    NativeVideoCompressionSettings? settings,
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
        bitrate: originalBitrate,
        frameRate: originalFrameRate
      ) = await videoInfoService.getVideoInformation(file.path);

      Logger.log('Original dimensions: ${originalWidth}x$originalHeight');

      final targetDimensions = _calculateTargetDimensions(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        maxDimension: settings?.height ?? NativeVideoCompressionSettings.defaultMaxDimension,
      );

      Logger.log('Target dimensions: ${targetDimensions.width}x${targetDimensions.height}');

      final quality = settings?.quality ?? 0.75;
      final frameRate = originalFrameRate?.round() ?? 30;
      final targetBitrate = _calculateTargetBitrate(
        width: targetDimensions.width,
        height: targetDimensions.height,
        frameRate: frameRate,
        quality: quality,
        originalBitrate: originalBitrate,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
      );

      Logger.log(
        'Time since start: ${stopwatch.elapsed.inSeconds}.${stopwatch.elapsed.inMilliseconds % 1000}s',
      );

      await _channel.invokeMethod('compressVideo', {
        'inputPath': file.path,
        'outputPath': output,
        'destWidth': targetDimensions.width,
        'destHeight': targetDimensions.height,
        'codec': settings?.codec,
        'quality': quality,
        if (targetBitrate != null) 'bitrate': targetBitrate,
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

      final context = <String, dynamic>{
        'compression_codec': settings?.codec,
        'compression_quality': settings?.quality,
        'compression_max_dimension': settings?.height,
      };
      await SentryService.logException(
        error,
        stackTrace: stackTrace,
        tag: 'native_video_compression_error',
        debugContext: context,
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
      targetHeight = maxDimension;
      targetWidth = (maxDimension * aspectRatio).round();
    } else {
      targetWidth = maxDimension;
      targetHeight = (maxDimension / aspectRatio).round();
    }

    // Align dimensions to multiples of 16 for Android hardware decoder compatibility
    // Many Android hardware decoders (e.g., some MediaTek) expect 16x16 macroblock alignment
    // and can produce corrupted frames for non-mod16 dimensions.
    // iOS VideoToolbox handles alignment internally, so skip alignment for iOS.
    if (!Platform.isIOS) {
      targetWidth = ((targetWidth + 15) ~/ 16) * 16;
      targetHeight = ((targetHeight + 15) ~/ 16) * 16;
    }

    return (width: targetWidth, height: targetHeight);
  }

  /// Calculates target bitrate using the same formula as Android for consistency.
  /// Formula: width * height * frameRate * bpp * qualityFactor
  /// - bpp (bits per pixel) = 0.08 for balanced quality
  /// - qualityFactor = quality (clamped 0.5-1.0)
  /// - Clamp result between 1 Mbps and 10 Mbps
  /// When re-encoding at same resolution, cap at original bitrate to prevent size increase.
  int? _calculateTargetBitrate({
    required int width,
    required int height,
    required int frameRate,
    required double quality,
    required int originalWidth,
    required int originalHeight,
    int? originalBitrate,
  }) {
    if (!Platform.isIOS) {
      return null;
    }

    const bpp = 0.08;
    final qualityFactor = quality.clamp(0.5, 1.0);
    final calculatedBitrate = (width * height * frameRate * bpp * qualityFactor).round();

    const minBitrate = 1000000;
    const maxBitrate = 10000000;
    var targetBitrate = calculatedBitrate.clamp(minBitrate, maxBitrate);

    final isSameResolution = width == originalWidth && height == originalHeight;
    if (isSameResolution && originalBitrate != null) {
      targetBitrate = targetBitrate < originalBitrate ? targetBitrate : originalBitrate;
      targetBitrate = targetBitrate.clamp(minBitrate, maxBitrate);
    }

    return targetBitrate;
  }
}

@Riverpod(keepAlive: true)
NativeVideoCompressor nativeVideoCompressor(Ref ref) => NativeVideoCompressor(
      videoInfoService: ref.read(videoInfoServiceProvider),
    );
