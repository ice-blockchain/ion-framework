// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/compressors/compress_executor.r.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/compressors/native_video_compressor.r.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_audio_bitrate_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_audio_codec_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_bitrate_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_crf_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_movflag_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_pixel_format_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_preset_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_scale_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_video_codec_arg.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_video_profile.dart';
import 'package:ion/app/services/media_service/ffmpeg_commands_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/media_service/video_info_service.r.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion/app/utils/video_codec_detector.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_compressor.r.g.dart';

class VideoCompressionSettings {
  const VideoCompressionSettings({
    required this.videoCodec,
    required this.preset,
    required this.crf,
    required this.maxRate,
    required this.bufSize,
    required this.scale,
    required this.audioCodec,
    required this.audioBitrate,
    required this.pixelFormat,
    required this.movFlags,
    required this.profile,
    this.videoBitrate,
  });

  static const balanced = VideoCompressionSettings(
    videoCodec: FFmpegVideoCodecArg.libx264,
    preset: FfmpegPresetArg.fast,
    crf: FfmpegCrfArg.balanced,
    maxRate: FfmpegBitrateArg.high,
    bufSize: FfmpegBitrateArg.highest,
    scale: FfmpegScaleArg.p1080Width,
    audioCodec: FfmpegAudioCodecArg.aac,
    audioBitrate: FfmpegAudioBitrateArg.medium,
    pixelFormat: FfmpegPixelFormatArg.yuv420p,
    movFlags: FfmpegMovFlagArg.faststart,
    profile: FfmpegProfileArg.main,
  );

  final FFmpegVideoCodecArg videoCodec;
  final FfmpegPresetArg preset;
  final FfmpegCrfArg crf;
  final FfmpegBitrateArg maxRate;
  final FfmpegBitrateArg bufSize;
  final FfmpegScaleArg scale;
  final FfmpegAudioCodecArg audioCodec;
  final FfmpegAudioBitrateArg audioBitrate;
  final FfmpegPixelFormatArg pixelFormat;
  final FfmpegMovFlagArg movFlags;
  final FfmpegBitrateArg? videoBitrate;
  final FfmpegProfileArg profile;
}

// Video duration threshold for using hardware compression
// Based on testing, the time difference between hardware and software compression is not significant
// until the video is longer than 25 seconds, but the file size is smaller with libx264
const hardwareCompressionThreshold = Duration(seconds: 20);

class VideoCompressor implements Compressor<VideoCompressionSettings> {
  VideoCompressor({
    required this.compressExecutor,
    required this.imageCompressor,
    required this.videoInfoService,
    required this.nativeVideoCompressor,
    required this.videoCodecDetector,
  });

  final CompressExecutor compressExecutor;
  final ImageCompressor imageCompressor;
  final VideoInfoService videoInfoService;
  final NativeVideoCompressor nativeVideoCompressor;
  final VideoCodecDetector videoCodecDetector;

  static const MethodChannel _channel = MethodChannel('ion/video_compression');

  /// Checks if the current device is an OPPO or OnePlus device.
  /// These devices have known issues with native video compression,
  /// so we use FFmpeg (software) compression instead.
  Future<bool> _isOppoDevice() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();
      return manufacturer == 'oppo' ||
          brand == 'oppo' ||
          manufacturer == 'oneplus' ||
          brand == 'oneplus';
    } catch (e) {
      Logger.warning('Failed to detect device manufacturer: $e');
      return false;
    }
  }

  String _formatBytes(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(2)} MB';
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inMilliseconds / 1000.0;
    return '${seconds.toStringAsFixed(2)} s';
  }

  Future<void> _logVideoError(
    Object error,
    StackTrace stackTrace,
    String tag,
    Map<String, dynamic>? fallbackContext,
  ) async {
    Logger.error(error, stackTrace: stackTrace, message: 'Error during video compression!');
    final debugContext = (error is CompressVideoException && error.context != null)
        ? error.context
        : (error is ExtractThumbnailException && error.context != null)
            ? error.context
            : fallbackContext;
    await SentryService.logException(
      error,
      stackTrace: stackTrace,
      tag: tag,
      debugContext: debugContext,
    );
  }

  ///
  /// Compresses a video file to a new file with the same name in the application cache directory.
  /// If success, returns a new [MediaFile] with the compressed video.
  /// If fails, throws an exception.
  ///
  @override
  Future<MediaFile> compress(
    MediaFile file, {
    Completer<FFmpegSession>? sessionIdCompleter,
    VideoCompressionSettings? settings,
  }) async {
    final videoInfo = await videoInfoService.getVideoInformation(file.path);
    final duration = videoInfo.duration.inSeconds;

    // Check if video is AV1 - FFmpeg can't decode AV1 on some devices (e.g., OPPO)
    // so we must use native compression for AV1 videos
    final isAV1 = await videoCodecDetector.isAV1Video(file.path);

    // Check if device is OPPO/OnePlus - use FFmpeg compression for these devices
    // to avoid native compression issues, EXCEPT for AV1 videos
    final isOppo = await _isOppoDevice();

    // Use native compression for:
    // 1. AV1 videos on non-OPPO devices (FFmpeg can't decode AV1 on some devices)
    // 2. Long videos on non-OPPO devices
    // For AV1 videos on OPPO devices, native compression fails during encoding,
    // so we skip compression and use the original file
    if (isAV1 && isOppo) {
      Logger.log('AV1 video on OPPO device - skipping compression due to encoder incompatibility');
      // Return original file with dimensions populated to ensure upload works
      return file.copyWith(
        width: videoInfo.width,
        height: videoInfo.height,
        duration: duration,
      );
    }

    if (isAV1 || (!isOppo && duration > hardwareCompressionThreshold.inSeconds)) {
      Logger.log(
        'Using native compression - isAV1: $isAV1, isOppo: $isOppo, duration: ${duration}s',
      );
      final nativeSettings = Platform.isAndroid
          ? AndroidNativeVideoCompressionSettings.balanced
          : IosNativeVideoCompressionSettings.balanced;

      try {
        return await nativeVideoCompressor.compress(
          file,
          settings: nativeSettings,
        );
      } catch (e) {
        // If native compression fails for AV1, fall back to original file
        if (isAV1) {
          Logger.warning('Native compression failed for AV1 video, using original file: $e');
          // Return original file with dimensions populated to ensure upload works
          return file.copyWith(
            width: videoInfo.width,
            height: videoInfo.height,
            duration: duration,
          );
        }
        rethrow;
      }
    }

    settings ??= VideoCompressionSettings.balanced;
    final originalVideoInfo = await videoInfoService.getVideoInformation(file.path);
    final originalBytes = await File(file.path).length();

    try {
      final output = await generateOutputPath(extension: 'mp4');
      final sessionResultCompleter = Completer<FFmpegSession>();

      final stopwatch = Stopwatch()..start();
      Logger.log('Original video size: ${_formatBytes(originalBytes)}');

      final args = FFmpegCommands.compressVideo(
        inputPath: file.path,
        outputPath: output,
        videoCodec: settings.videoCodec.codec,
        preset: settings.preset.value,
        crf: settings.crf.value,
        maxRate: settings.maxRate.bitrate,
        bufSize: settings.bufSize.bitrate,
        audioCodec: settings.audioCodec.codec,
        audioBitrate: settings.audioBitrate.bitrate,
        pixelFormat: settings.pixelFormat.name,
        scaleResolution: settings.scale.resolution,
        movFlags: settings.movFlags.value,
        profile: settings.profile.value,
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
        Logger.log('Failed to compress video. Logs: $logs');
        throw CompressVideoException(
          returnCode,
          context: {
            'video_file_size_bytes': originalBytes,
            'video_duration_seconds': originalVideoInfo.duration.inSeconds,
            'video_resolution': '${originalVideoInfo.width}x${originalVideoInfo.height}',
            'compression_codec': settings.videoCodec.codec,
            'compression_preset': settings.preset.value,
            'compression_crf': settings.crf.value,
            'compression_max_rate': settings.maxRate.bitrate,
            'compression_buf_size': settings.bufSize.bitrate,
            'ffmpeg_return_code': returnCode?.toString(),
            'ffmpeg_logs': logs,
          },
        );
      }

      final compressedBytes = await File(output).length();
      stopwatch.stop();
      Logger.log('Compressed video size: ${_formatBytes(compressedBytes)}');
      Logger.log('Compression time: ${_formatDuration(stopwatch.elapsed)}');

      final (
        width: outWidth,
        height: outHeight,
        duration: outDuration,
        bitrate: outBitrate,
        frameRate: _
      ) = await videoInfoService.getVideoInformation(output);

      // Return the final compressed video file info
      return MediaFile(
        path: output,
        mimeType: MimeType.video.value,
        originalMimeType: file.originalMimeType,
        name: file.name,
        width: outWidth,
        height: outHeight,
        duration: outDuration.inSeconds,
      );
    } catch (error, stackTrace) {
      await _logVideoError(
        error,
        stackTrace,
        'video_compression_error',
        {
          'video_file_size_bytes': originalBytes,
          'video_duration_seconds': originalVideoInfo.duration.inSeconds,
          'video_resolution': '${originalVideoInfo.width}x${originalVideoInfo.height}',
          'compression_codec': settings.videoCodec.codec,
          'compression_preset': settings.preset.value,
          'compression_crf': settings.crf.value,
          'compression_max_rate': settings.maxRate.bitrate,
          'compression_buf_size': settings.bufSize.bitrate,
        },
      );
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
    String? timestamp,
  }) async {
    try {
      var thumbPath = thumb;

      // If no external thumb was provided, extract a single frame from the video
      if (thumbPath == null) {
        final outputPath = await generateOutputPath();

        // Check if video is AV1 and use native Android method as fallback
        final isAV1 = await videoCodecDetector.isAV1Video(videoFile.path);
        if (isAV1 && Platform.isAndroid) {
          try {
            await _extractThumbnailNative(videoFile.path, outputPath, timestamp);
            thumbPath = outputPath;
          } catch (nativeError) {
            Logger.warning(
              'Native thumbnail extraction failed for AV1 video, falling back to FFmpeg: $nativeError',
            );
            // Fall through to FFmpeg attempt
            thumbPath = await _extractThumbnailFFmpeg(
              videoFile.path,
              outputPath,
              timestamp,
            );
          }
        } else {
          thumbPath = await _extractThumbnailFFmpeg(
            videoFile.path,
            outputPath,
            timestamp,
          );
        }
      }

      final compressedImage = await imageCompressor.compress(
        MediaFile(path: thumbPath),
      );

      return compressedImage;
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: 'Error during thumbnail extraction!');
      await _logVideoError(
        error,
        stackTrace,
        'video_thumbnail_error',
        {'thumbnail_timestamp': timestamp},
      );
      rethrow;
    }
  }

  Future<String> _extractThumbnailFFmpeg(
    String videoPath,
    String outputPath,
    String? timestamp,
  ) async {
    final sessionResultCompleter = Completer<FFmpegSession>();
    final session = await compressExecutor.execute(
      FFmpegCommands.extractThumbnail(
        videoPath: videoPath,
        outputPath: outputPath,
        timestamp: timestamp ?? '00:00:01.000',
      ),
      sessionResultCompleter,
    );

    await sessionResultCompleter.future;

    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      final videoInfo = await videoInfoService.getVideoInformation(videoPath);
      final videoCodec = await videoInfoService.getVideoCodec(videoPath);
      throw ExtractThumbnailException(
        returnCode,
        context: {
          'video_duration_seconds': videoInfo.duration.inSeconds,
          'video_resolution': '${videoInfo.width}x${videoInfo.height}',
          'video_codec': videoCodec ?? 'unknown',
          'thumbnail_timestamp': timestamp,
          'ffmpeg_return_code': returnCode?.toString(),
          'ffmpeg_logs': logs,
        },
      );
    }
    return outputPath;
  }

  /// Parses a timestamp string in HH:MM:SS.mmm format to microseconds.
  /// Returns null if parsing fails.
  int? _parseTimestampToMicroseconds(String timestamp) {
    try {
      // Format: HH:MM:SS.mmm - parse using regex for cleaner extraction
      final match = RegExp(r'^(\d+):(\d+):(\d+)(?:\.(\d+))?$').firstMatch(timestamp);
      if (match == null) return null;

      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final milliseconds = match.group(4) != null ? int.parse(match.group(4)!) : 0;

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      ).inMicroseconds;
    } catch (e) {
      Logger.warning('Failed to parse timestamp $timestamp: $e');
      return null;
    }
  }

  Future<void> _extractThumbnailNative(
    String videoPath,
    String outputPath,
    String? timestamp,
  ) async {
    // Parse timestamp to microseconds, default to 1 second if parsing fails
    final timeUs =
        timestamp != null ? _parseTimestampToMicroseconds(timestamp) ?? 1000000 : 1000000;

    await _channel.invokeMethod('extractThumbnail', {
      'videoPath': videoPath,
      'outputPath': outputPath,
      'timeUs': timeUs,
    });
  }
}

@Riverpod(keepAlive: true)
VideoCompressor videoCompressor(Ref ref) => VideoCompressor(
      compressExecutor: ref.read(compressExecutorProvider),
      imageCompressor: ref.read(imageCompressorProvider),
      videoInfoService: ref.read(videoInfoServiceProvider),
      nativeVideoCompressor: ref.read(nativeVideoCompressorProvider),
      videoCodecDetector: ref.read(videoCodecDetectorProvider),
    );
