// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/compressors/compress_executor.r.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_audio_bitrate_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_audio_codec_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_bitrate_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_movflag_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_pixel_format_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_preset_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_scale_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_video_codec_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_commands_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_compressor.r.g.dart';

class VideoCompressionSettings {
  const VideoCompressionSettings({
    required this.videoCodec,
    required this.preset,
    required this.maxRate,
    required this.bufSize,
    required this.scale,
    required this.audioCodec,
    required this.audioBitrate,
    required this.pixelFormat,
    required this.movFlags,
  });

  static const balanced = VideoCompressionSettings(
    videoCodec: FFmpegVideoCodecArg.h264,
    preset: FfmpegPresetArg.slow,
    maxRate: FfmpegBitrateArg.medium,
    bufSize: FfmpegBitrateArg.medium,
    scale: FfmpegScaleArg.p1080,
    audioCodec: FfmpegAudioCodecArg.aac,
    audioBitrate: FfmpegAudioBitrateArg.medium,
    pixelFormat: FfmpegPixelFormatArg.yuv420p,
    movFlags: FfmpegMovFlagArg.faststart,
  );

  static const highQuality = VideoCompressionSettings(
    videoCodec: FFmpegVideoCodecArg.h264,
    preset: FfmpegPresetArg.slow,
    maxRate: FfmpegBitrateArg.high,
    bufSize: FfmpegBitrateArg.highest,
    scale: FfmpegScaleArg.p1080,
    audioCodec: FfmpegAudioCodecArg.aac,
    audioBitrate: FfmpegAudioBitrateArg.medium,
    pixelFormat: FfmpegPixelFormatArg.yuv420p,
    movFlags: FfmpegMovFlagArg.faststart,
  );

  final FFmpegVideoCodecArg videoCodec;
  final FfmpegPresetArg preset;
  final FfmpegBitrateArg maxRate;
  final FfmpegBitrateArg bufSize;
  final FfmpegScaleArg scale;
  final FfmpegAudioCodecArg audioCodec;
  final FfmpegAudioBitrateArg audioBitrate;
  final FfmpegPixelFormatArg pixelFormat;
  final FfmpegMovFlagArg movFlags;
}

class VideoCompressor implements Compressor<VideoCompressionSettings> {
  VideoCompressor({
    required this.compressExecutor,
    required this.imageCompressor,
  });

  final CompressExecutor compressExecutor;
  final ImageCompressor imageCompressor;

  ///
  /// Compresses a video file to a new file with the same name in the application cache directory.
  /// If success, returns a new [MediaFile] with the compressed video.
  /// If fails, throws an exception.
  ///
  @override
  Future<MediaFile> compress(
    MediaFile file, {
    Completer<FFmpegSession>? sessionIdCompleter,
    VideoCompressionSettings settings = VideoCompressionSettings.highQuality,
  }) async {
    try {
      final output = await generateOutputPath(extension: 'mp4');
      final sessionResultCompleter = Completer<FFmpegSession>();

      final args = FFmpegCommands.compressVideo(
        inputPath: file.path,
        outputPath: output,
        videoCodec: settings.videoCodec.codec,
        preset: settings.preset.value,
        maxRate: settings.maxRate.bitrate,
        bufSize: settings.bufSize.bitrate,
        audioCodec: settings.audioCodec.codec,
        audioBitrate: settings.audioBitrate.bitrate,
        pixelFormat: settings.pixelFormat.name,
        scaleResolution: settings.scale.resolution,
        movFlags: settings.movFlags.value,
      );

      final session = await compressExecutor.execute(
        args,
        sessionResultCompleter,
        sessionIdCompleter: sessionIdCompleter,
      );

      await sessionResultCompleter.future;

      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        final stackTrace = await session.getFailStackTrace();
        Logger.log('Failed to compress video. Logs: $logs, StackTrace: $stackTrace');
        throw CompressVideoException(returnCode);
      }

      final (width: outWidth, height: outHeight) = await getVideoDimensions(output);

      // Return the final compressed video file info
      return MediaFile(
        path: output,
        mimeType: MimeType.video.value,
        originalMimeType: file.originalMimeType,
        name: file.name,
        width: outWidth,
        height: outHeight,
        duration: file.duration,
      );
    } catch (error, stackTrace) {
      Logger.log('Error during video compression!', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  ///
  /// Extracts a thumbnail from a video file or processes the provided [thumb].
  /// If success, returns a new [MediaFile] with the thumbnail.
  /// If fails, throws an exception.
  ///
  Future<MediaFile> getThumbnail(
    MediaFile videoFile, {
    String? thumb,
  }) async {
    try {
      var thumbPath = thumb;
      final sessionResultCompleter = Completer<FFmpegSession>();

      // If no external thumb was provided, extract a single frame from the video
      if (thumbPath == null) {
        final outputPath = await generateOutputPath();
        final session = await compressExecutor.execute(
          FFmpegCommands.extractThumbnail(
            videoPath: videoFile.path,
            outputPath: outputPath,
          ),
          sessionResultCompleter,
        );

        await sessionResultCompleter.future;

        final returnCode = await session.getReturnCode();
        if (!ReturnCode.isSuccess(returnCode)) {
          throw ExtractThumbnailException(returnCode);
        }
        thumbPath = outputPath;
      }

      final compressedImage = await imageCompressor.compress(
        MediaFile(path: thumbPath),
      );

      return compressedImage;
    } catch (error, stackTrace) {
      Logger.log('Error during thumbnail extraction!', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  ///
  /// Get width and height for a video file by probing it with FFprobeKit.
  ///
  Future<({int width, int height})> getVideoDimensions(String videoPath) async {
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

  Future<Duration?> getVideoDuration(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final mediaInformation = session.getMediaInformation();

      if (mediaInformation != null) {
        final durationString = mediaInformation.getDuration();
        if (durationString != null) {
          final durationSeconds = double.parse(durationString);
          return Duration(milliseconds: (durationSeconds * 1000).round());
        }
      }
    } catch (e, stackTrace) {
      Logger.log('Error during video duration extraction!', error: e, stackTrace: stackTrace);
      return null;
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
VideoCompressor videoCompressor(Ref ref) => VideoCompressor(
      compressExecutor: ref.read(compressExecutorProvider),
      imageCompressor: ref.read(imageCompressorProvider),
    );
