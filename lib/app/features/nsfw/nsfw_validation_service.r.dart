// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/nsfw_detector_factory.r.dart';
import 'package:ion/app/features/nsfw/services/nsfw_isolate_functions.dart';
import 'package:ion/app/features/nsfw/services/nsfw_model_manager.r.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/media_service/video_info_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nsfw_validation_service.r.g.dart';

@riverpod
Future<NsfwValidationService> nsfwValidationService(Ref ref) async => NsfwValidationService(
      detectorFactory: await ref.read(nsfwDetectorFactoryProvider.future),
      videoCompressor: ref.read(videoCompressorProvider),
      videoInfoService: ref.read(videoInfoServiceProvider),
      nsfwModelManager: ref.read(nsfwModelManagerProvider),
    );

class NsfwValidationService {
  NsfwValidationService({
    required this.detectorFactory,
    required this.videoCompressor,
    required this.videoInfoService,
    required this.nsfwModelManager,
  });

  final NsfwDetectorFactory detectorFactory;
  final VideoCompressor videoCompressor;
  final VideoInfoService videoInfoService;
  final NsfwModelManager nsfwModelManager;

  /// Combined validation: images + videos in single isolate call
  /// Uses one-shot isolate (spawns new isolate per call)
  Future<Map<String, bool>> hasNsfwInMediaFiles(
    List<MediaFile> mediaFiles,
  ) async {
    // 1. Extract images and videos
    final imageFiles = mediaFiles.where(_isImageMedia).toList();
    final videoFiles = _extractVideoFiles(mediaFiles);

    // 2. Extract video thumbnails (main thread, heavy I/O)
    final thumbnailPathToVideoPath = <String, String>{};
    final thumbnailPathToBytes = <String, Uint8List>{};

    for (final video in videoFiles) {
      final timestamps = await _buildTimestamps(video);

      for (final ts in timestamps) {
        try {
          final thumbMediaFile = await videoCompressor.getThumbnail(video, timestamp: ts);
          final bytes = await File(thumbMediaFile.path).readAsBytes();

          thumbnailPathToBytes[thumbMediaFile.path] = bytes;
          thumbnailPathToVideoPath[thumbMediaFile.path] = video.path;
        } catch (e, st) {
          Logger.error(e, message: 'NSFW video thumbnail validation failed', stackTrace: st);
        }
      }
    }

    // 3. Build combined pathToBytes map (images + thumbnails)
    final combinedPathToBytes = <String, Uint8List>{};

    // Add images
    for (final imageFile in imageFiles) {
      try {
        final bytes = await File(imageFile.path).readAsBytes();
        combinedPathToBytes[imageFile.path] = bytes;
      } catch (e) {
        Logger.warning('Failed to read image for NSFW check: ${imageFile.path}: $e');
      }
    }

    // Add thumbnails
    combinedPathToBytes.addAll(thumbnailPathToBytes);

    if (combinedPathToBytes.isEmpty) {
      return {};
    }

    // 4. Single isolate call with all media (one-shot isolate)
    final modelPath = await nsfwModelManager.getModelPath();
    Map<String, NsfwResult> results;
    try {
      results = await compute(
        nsfwCheckAllMediaOneShotFn,
        [modelPath, detectorFactory.blockThreshold, combinedPathToBytes],
      );
    } catch (e, st) {
      Logger.error(e, message: 'NSFW combined isolate failed', stackTrace: st);
      return {};
    }

    // 5. Aggregate results back to media files
    final finalResults = <String, bool>{};

    // Direct image results
    for (final imageFile in imageFiles) {
      final result = results[imageFile.path];
      if (result != null) {
        final isNsfw = result.decision == NsfwDecision.block;
        finalResults[imageFile.path] = isNsfw;
      }
    }

    // Aggregate thumbnail results to videos (any thumbnail NSFW = video NSFW)
    for (final videoFile in videoFiles) {
      final videoThumbnails = thumbnailPathToVideoPath.entries
          .where((entry) => entry.value == videoFile.path)
          .map((entry) => entry.key)
          .toList();

      if (videoThumbnails.isEmpty) {
        // No thumbnails extracted, mark as safe
        finalResults[videoFile.path] = false;
        continue;
      }

      // Check if any thumbnail is NSFW
      final videoIsNsfw = videoThumbnails.any(
        (thumbPath) => results[thumbPath]?.decision == NsfwDecision.block,
      );

      finalResults[videoFile.path] = videoIsNsfw;
    }

    return finalResults;
  }

  Future<Map<String, bool>> hasNsfwInImagePaths(List<String> paths) async {
    if (paths.isEmpty) {
      return {};
    }

    final imagePaths = paths.where(_isImageExtension).toList();

    // Prepare path → bytes map
    final pathToBytes = <String, Uint8List>{};

    for (final path in imagePaths) {
      try {
        final bytes = await File(path).readAsBytes();
        pathToBytes[path] = bytes;
      } catch (e) {
        Logger.warning('Failed to read image for NSFW check: $path: $e');
      }
    }

    if (pathToBytes.isEmpty) {
      return {};
    }

    final modelPath = await nsfwModelManager.getModelPath();

    Map<String, NsfwResult> results;
    try {
      results = await compute(
        nsfwCheckAllMediaOneShotFn,
        [modelPath, detectorFactory.blockThreshold, pathToBytes],
      );
    } catch (e, st) {
      Logger.error(e, message: 'NSFW image isolate failed', stackTrace: st);
      return {};
    }

    final finalResults = results.map(
      (path, result) => MapEntry(path, result.decision == NsfwDecision.block),
    );

    return finalResults;
  }

  bool _isImageMedia(MediaFile media) {
    final mime = media.mimeType ?? '';
    if (mime.startsWith('image/')) return true;
    return _isImageExtension(media.path);
  }

  bool _isImageExtension(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  List<MediaFile> _extractVideoFiles(List<MediaFile> mediaFiles) {
    return mediaFiles.where((m) {
      final mime = m.mimeType ?? '';
      return mime.startsWith('video/');
    }).toList();
  }

  Future<List<String>> _buildTimestamps(MediaFile video) async {
    final durationMs = video.duration ??
        (await videoInfoService.getVideoInformation(video.path)).duration.inMilliseconds;
    if (durationMs <= 0) {
      return ['00:00:01.000', '00:00:03.000', '00:00:05.000'];
    }

    final d = durationMs;
    final positions = [0.05, 0.30, 0.60, 0.85];
    return positions.map((p) => _formatTimestamp((d * p).round())).toList();
  }

  String _formatTimestamp(int ms) {
    final seconds = (ms / 1000).floor();
    final millis = ms % 1000;
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }
}
