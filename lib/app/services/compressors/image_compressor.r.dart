// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
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
  jpeg;

  String get mimeType => switch (this) {
        webp => MimeType.image.value,
        // We use this for push notifications only
        jpeg => LocalMimeType.jpeg.value,
      };
}

class ImageCompressionSettings {
  const ImageCompressionSettings({
    this.quality = 90,
    this.shouldCompressGif = false,
    this.scaleResolution = FfmpegScaleArg.p1080Width,
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
    Completer<FFmpegSession>? sessionIdCompleter,
    ImageCompressionType to = ImageCompressionType.webp,
    ImageCompressionSettings settings = const ImageCompressionSettings(),
  }) async {
    try {
      final isWebP = to == ImageCompressionType.webp &&
          (file.mimeType == ImageCompressionType.webp.mimeType ||
              file.path.toLowerCase().endsWith('.webp'));
      if (isWebP) {
        if (file.width == null || file.height == null) {
          final imageDimensions = await getImageDimension(path: file.path);
          return file.copyWith(
            width: imageDimensions.width,
            height: imageDimensions.height,
            mimeType: file.mimeType ?? ImageCompressionType.webp.mimeType,
          );
        }
        return file;
      }

      final output = await generateOutputPath(extension: to.name);

      final isGif =
          file.mimeType == LocalMimeType.gif.value && file.path.isGif && settings.shouldCompressGif;

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
        case ImageCompressionType.jpeg:
          command = FFmpegCommands.webpToJpeg(
            inputPath: file.path,
            outputPath: output,
            quality: settings.quality,
            scaleResolution: settings.scaleResolution.resolution,
          );
      }

      final sessionResultCompleter = Completer<FFmpegSession>();

      await compressExecutor.execute(
        command,
        sessionResultCompleter,
        sessionIdCompleter: sessionIdCompleter,
      );

      final session = await sessionResultCompleter.future;

      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        final stackTrace = await session.getFailStackTrace();
        Logger.log('Failed to compress image. Logs: $logs, StackTrace: $stackTrace');
        throw CompressImageException(returnCode);
      }

      // For images, we can easily decode to get actual width/height
      final outputDimension = await getImageDimension(path: output);

      // If it's a gif, we need to indicate that it's a webp with the gif extension
      final mimeType = isGif ? MimeType.gif.value : to.mimeType;

      return MediaFile(
        path: output,
        mimeType: mimeType,
        originalMimeType: file.originalMimeType,
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

  ///
  /// scale image
  ///
  Future<MediaFile> scaleImage(
    MediaFile file, {
    FfmpegScaleArg scaleResolution = FfmpegScaleArg.p240,
    int quality = 70,
  }) async {
    if (file.mimeType != MimeType.image.value) {
      throw CompressImageException(Exception('Mime type is not supported for scaling'));
    }

    final sessionIdCompleter = Completer<FFmpegSession>();

    final output = await generateOutputPath(extension: '.webp');
    final command = FFmpegCommands.scaleImageToThumbnail(
      inputPath: file.path,
      outputPath: output,
      scaleResolution: scaleResolution.resolution,
      quality: quality,
    );

    final session = await compressExecutor.execute(command, sessionIdCompleter);
    await sessionIdCompleter.future;

    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      final stackTrace = await session.getFailStackTrace();
      Logger.log('Failed to scale image to thumbnail. Logs: $logs, StackTrace: $stackTrace');
      throw CompressImageException(returnCode);
    }
    final outputDimension = await getImageDimension(path: output);
    return MediaFile(
      path: output,
      mimeType: file.mimeType,
      originalMimeType: file.originalMimeType,
      width: outputDimension.width,
      height: outputDimension.height,
    );
  }
}

@Riverpod(keepAlive: true)
ImageCompressor imageCompressor(Ref ref) => ImageCompressor(
      compressExecutor: ref.read(compressExecutorProvider),
    );
