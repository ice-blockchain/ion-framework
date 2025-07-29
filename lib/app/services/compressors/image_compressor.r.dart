// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:ui';

import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/services/compressors/compress_executor.r.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_scale_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_commands_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/image_path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_compressor.r.g.dart';

enum ImageCompressionType {
  webp,
  jpg,
}

class ImageCompressionSettings {
  const ImageCompressionSettings({
    this.quality = 70,
    this.shouldCompressGif = false,
    this.scaleResolution = FfmpegScaleArg.fullHd,
  });

  final int quality;
  final bool shouldCompressGif;
  final FfmpegScaleArg scaleResolution;
}

class ImageCompressor implements Compressor<ImageCompressionSettings> {
  const ImageCompressor({required this.compressExecutor});

  final CompressExecutor compressExecutor;

  ///
  /// Compresses an image file to webp format.
  /// If success, returns a new [MediaFile] with the compressed image.
  /// If fails, throws an exception.
  ///
  @override
  Future<MediaFile> compress(
    MediaFile file, {
    ImageCompressionType to = ImageCompressionType.webp,
    ImageCompressionSettings settings = const ImageCompressionSettings(),
  }) async {
    try {
      final isWebP = to == ImageCompressionType.webp &&
          (file.mimeType == 'image/webp' || file.path.toLowerCase().endsWith('.webp'));
      if (isWebP) {
        if (file.width == null || file.height == null) {
          final imageDimensions = await getImageDimension(path: file.path);
          return file.copyWith(
            width: imageDimensions.width,
            height: imageDimensions.height,
            mimeType: file.mimeType ?? 'image/webp',
          );
        }
        return file;
      }

      final output = await generateOutputPath(extension: to.name);

      final isGif = file.mimeType == 'image/gif' && file.path.isGif && settings.shouldCompressGif;

      List<String> command;

      switch (to) {
        case ImageCompressionType.webp:
          if (isGif) {
            command = FFmpegCommands.gifToAnimatedWebP(
              inputPath: file.path,
              outputPath: output,
              quality: settings.quality,
            );
          } else {
            command = FFmpegCommands.imageToWebP(
              inputPath: file.path,
              outputPath: output,
              quality: settings.quality,
              scaleResolution: settings.scaleResolution.resolution,
            );
          }
        case ImageCompressionType.jpg:
          command = FFmpegCommands.webpToJpeg(
            inputPath: file.path,
            outputPath: output,
            quality: settings.quality,
            scaleResolution: settings.scaleResolution.resolution,
          );
      }

      final session = await compressExecutor.execute(command);

      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        final stackTrace = await session.getFailStackTrace();
        Logger.log('Failed to compress image. Logs: $logs, StackTrace: $stackTrace');
        throw CompressImageException(returnCode);
      }

      // For images, we can easily decode to get actual width/height
      final outputDimension = await getImageDimension(path: output);

      return MediaFile(
        path: output,
        mimeType: switch (to) {
          ImageCompressionType.jpg => 'image/jpeg',
          ImageCompressionType.webp => isGif ? 'image/gif+webp' : 'image/webp',
        },
        width: outputDimension.width,
        height: outputDimension.height,
      );
    } catch (error, stackTrace) {
      Logger.log('Error during image compression!', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  ///
  /// Get width and height for a bitmap image (PNG, JPEG, WebP, etc.)
  ///
  Future<({int width, int height})> getImageDimension({required String path}) async {
    final file = File(path);
    final imageBytes = await file.readAsBytes();
    final codec = await instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return (width: image.width, height: image.height);
  }
}

@Riverpod(keepAlive: true)
ImageCompressor imageCompressor(Ref ref) => ImageCompressor(
      compressExecutor: ref.read(compressExecutorProvider),
    );
