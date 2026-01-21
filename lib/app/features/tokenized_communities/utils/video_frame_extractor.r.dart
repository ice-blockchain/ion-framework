// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/media_service/video_info_service.r.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_frame_extractor.r.g.dart';

/// Extracts 10-30 diverse frames from a video file.
/// The frames are distributed across the video duration to capture
/// different moments and provide better context about the video content.
///
/// Returns a list of base64-encoded image strings.
@riverpod
Future<List<String>> extractVideoFrames(
  Ref ref,
  String videoPath,
) async {
  try {
    final videoInfo = await ref.read(videoInfoServiceProvider).getVideoInformation(videoPath);
    final durationMs = videoInfo.duration.inMilliseconds;

    if (durationMs <= 0) {
      return [];
    }

    // Extract 10-30 frames distributed across the video
    // Use more frames for longer videos
    final numFrames = (durationMs / 1000).clamp(10, 30).round();

    // Distribute frames across the video duration
    // Skip the very beginning (0%) and end (100%) to avoid black frames
    const startPercent = 0.05;
    const endPercent = 0.95;
    final step = (endPercent - startPercent) / (numFrames - 1);

    final frames = <String>[];
    final videoCompressor = ref.read(videoCompressorProvider);

    for (var i = 0; i < numFrames; i++) {
      final percent = startPercent + (step * i);
      final timestampMs = (durationMs * percent).round();
      final timestamp = _formatTimestamp(timestampMs);

      try {
        // Extract frame at this timestamp
        final videoFile = MediaFile(path: videoPath, duration: durationMs);
        final thumbnail = await videoCompressor.getThumbnail(
          videoFile,
          timestamp: timestamp,
        );

        // Read the thumbnail file and convert to base64
        final file = File(thumbnail.path);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          final base64 = _base64Encode(bytes);
          frames.add(base64);

          // Clean up temporary file
          try {
            file.deleteSync();
          } catch (_) {
            // Ignore cleanup errors
          }
        }
      } catch (e) {
        // Skip frames that fail to extract, continue with others
        continue;
      }
    }

    return frames;
  } catch (error, stackTrace) {
    Logger.error(error, stackTrace: stackTrace, message: 'Error extracting video frames');
    return [];
  }
}

@riverpod
Future<List<String>> extractVideoFramesFromEntity(
  Ref ref,
  dynamic entity,
) async {
  final frames = <String>[];
  if (entity is ModifiablePostEntity) {
    if (entity.data.hasVideo) {
      final videos = entity.data.videos;
      if (videos.isNotEmpty) {
        for (final video in videos) {
          final videoUrl = video.url;
          String? videoPath;

          if (isNetworkUrl(videoUrl)) {
            // Use cache manager to return cached file or download and cache it.
            try {
              final cachedFile = await IONCacheManager.networkVideos.getSingleFile(videoUrl);
              videoPath = cachedFile.path;
            } catch (e, stacktrace) {
              Logger.error(
                e,
                stackTrace: stacktrace,
                message: 'extractVideoFramesFromEntity, error',
              );
              videoPath = null;
            }
          }

          // If we have a local path, try to extract frames
          if (videoPath != null) {
            try {
              final file = File(videoPath);
              if (file.existsSync()) {
                final extractedFrames =
                    await ref.read(extractVideoFramesProvider(videoPath).future);

                // Add MIME type prefix to each frame (video frames are JPEG image thumbnails)
                final framesWithMimeType =
                    extractedFrames.map((frame) => 'data:image/webp;base64,$frame').toList();
                frames.addAll(framesWithMimeType);
              }
            } catch (error, stackTrace) {
              Logger.error(
                error,
                stackTrace: stackTrace,
                message: 'Error extracting video frames from entity',
              );
              // Silently fail - video frame extraction is optional
            }
          }
        }
      }
    }
  }

  return frames;
}

String _formatTimestamp(int ms) {
  final seconds = (ms / 1000).floor();
  final millis = ms % 1000;
  final minutes = (seconds / 60).floor();
  final hours = (minutes / 60).floor();
  final secs = seconds % 60;
  final mins = minutes % 60;

  return '${hours.toString().padLeft(2, '0')}:'
      '${mins.toString().padLeft(2, '0')}:'
      '${secs.toString().padLeft(2, '0')}.'
      '${millis.toString().padLeft(3, '0')}';
}

String _base64Encode(List<int> bytes) {
  // Use base64 encoding without data URL prefix
  // The API expects just the base64 string
  return base64Encode(bytes);
}
