// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
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
import 'package:video_toolbox/video_toolbox.dart';
import 'package:video_toolbox/video_toolbox_platform_interface.dart';

part 'ios_native_video_compressor.r.g.dart';

class IosNativeVideoCompressionSettings {
  const IosNativeVideoCompressionSettings({
    required this.bitRate,
    required this.width,
    required this.height,
  });

  static const balanced = IosNativeVideoCompressionSettings(
    bitRate: 1000000,
    width: 1920,
    height: 1080,
  );

  final int bitRate;
  final int width;
  final int height;
}

class IosNativeVideoCompressor implements Compressor<IosNativeVideoCompressionSettings> {
  IosNativeVideoCompressor({
    required this.imageCompressor,
    required this.compressExecutor,
  });

  final ImageCompressor imageCompressor;
  final CompressExecutor compressExecutor;
  final VideoToolbox _videoToolbox = VideoToolbox();

  @override
  Future<MediaFile> compress(
    MediaFile file, {
    IosNativeVideoCompressionSettings? settings,
  }) async {
    try {
      final output = await generateOutputPath(extension: 'mp4');

      final (width: originalWidth, height: originalHeight) = await _getVideoDimensions(file.path);

      final targetDimensions = _calculateTargetDimensions(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        maxDimension: max(settings?.width ?? 0, settings?.height ?? 0),
      );

      final targetBitrate = settings?.bitRate ?? 2500000;

      await _videoToolbox.compressVideo(
        inputPath: file.path,
        outputPath: output,
        destBitRate: targetBitrate,
        destWidth: targetDimensions.width,
        destHeight: targetDimensions.height,
        codec: VideoCodec.hevc,
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

  Future<({int width, int height})> _getVideoDimensions(String videoPath) async {
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
    return (width: width, height: height);
  }
}

@Riverpod(keepAlive: true)
IosNativeVideoCompressor iosNativeVideoCompressor(Ref ref) => IosNativeVideoCompressor(
      imageCompressor: ref.read(imageCompressorProvider),
      compressExecutor: ref.read(compressExecutorProvider),
    );
