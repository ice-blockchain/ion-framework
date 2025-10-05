// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/compressors/compress_executor.r.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ios_native_video_compressor.r.g.dart';

class IosNativeVideoCompressionSettings {
  const IosNativeVideoCompressionSettings({
    required this.height,
    required this.quality,
    required this.realtime,
  });

  static const balanced = IosNativeVideoCompressionSettings(
    quality: 0.5,
    height: 1080,
    realtime: true,
  );

  final int height;
  final double quality; // 0.0 - 1.0, where 1.0 is highest quality (VBR encoding)
  final bool realtime; // expectsMediaDataInRealTime parameter
}

class IosNativeVideoCompressor implements Compressor<IosNativeVideoCompressionSettings> {
  IosNativeVideoCompressor({
    required this.imageCompressor,
    required this.compressExecutor,
  });

  final ImageCompressor imageCompressor;
  final CompressExecutor compressExecutor;

  static const MethodChannel _channel = MethodChannel('ion/video_compression');

  @override
  Future<MediaFile> compress(
    MediaFile file, {
    IosNativeVideoCompressionSettings? settings,
  }) async {
    try {
      final startTime = DateTime.now();
      final originalFile = File(file.path);
      final originalSize = await originalFile.length();

      Logger.log('Original video size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      final output = await generateOutputPath(extension: 'mp4');

      final (width: originalWidth, height: originalHeight, bitrate: originalBitrate) =
          await _getVideoDimensions(file.path);
      Logger.log('Original dimensions: ${originalWidth}x$originalHeight');
      if (originalBitrate != null) {
        Logger.log('Original bitrate: ${(originalBitrate / 1000000).toStringAsFixed(2)} Mbps');
      }

      final targetDimensions = _calculateTargetDimensions(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        maxDimension: settings?.height ?? 1080,
      );

      Logger.log('Target dimensions: ${targetDimensions.width}x${targetDimensions.height}');

      Logger.log(
        'Time since start: ${DateTime.now().difference(startTime).inSeconds}.${DateTime.now().difference(startTime).inMilliseconds % 1000}s',
      );

      await _channel.invokeMethod('compressVideo', {
        'inputPath': file.path,
        'outputPath': output,
        'destWidth': targetDimensions.width,
        'destHeight': targetDimensions.height,
        'codec': 'h264',
        'quality': settings?.quality,
        'realtime': false,
      });

      final compressedFile = File(output);
      final compressedSize = await compressedFile.length();
      final compressionTime = DateTime.now().difference(startTime);

      Logger.log(
        'Compressed video size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      Logger.log(
        'Compression time: ${compressionTime.inSeconds}.${compressionTime.inMilliseconds % 1000}s',
      );

      return MediaFile(
        path: output,
        mimeType: MimeType.video.value,
        originalMimeType: file.originalMimeType,
        name: file.name,
        width: targetDimensions.width,
        height: targetDimensions.height,
        duration: file.duration,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
      );
      rethrow;
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

  Future<({int width, int height, int? bitrate})> _getVideoDimensions(String videoPath) async {
    final infoSession = await FFprobeKit.getMediaInformation(videoPath);
    final info = infoSession.getMediaInformation();
    if (info == null) {
      throw UnknownFileResolutionException(
        'No media information found for: $videoPath',
      );
    }
    final streams = info.getStreams();
    if (streams.isEmpty) {
      throw UnknownFileResolutionException(
        'No streams found in media: $videoPath',
      );
    }

    final videoStream = streams.firstWhere(
      (s) => s.getType() == 'video',
      orElse: () => throw UnknownFileResolutionException(
        'No video stream found in file: $videoPath',
      ),
    );

    final width = videoStream.getWidth();
    final height = videoStream.getHeight();
    if (width == null || height == null) {
      throw UnknownFileResolutionException(
        'Could not determine video resolution for: $videoPath',
      );
    }

    final bitrateString = videoStream.getBitrate();
    final bitrate = bitrateString != null ? int.tryParse(bitrateString) : null;

    return (width: width, height: height, bitrate: bitrate);
  }
}

@Riverpod(keepAlive: true)
IosNativeVideoCompressor iosNativeVideoCompressor(Ref ref) => IosNativeVideoCompressor(
      imageCompressor: ref.read(imageCompressorProvider),
      compressExecutor: ref.read(compressExecutorProvider),
    );
