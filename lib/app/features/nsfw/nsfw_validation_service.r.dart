// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/nsfw_detector_factory.r.dart';
import 'package:ion/app/features/nsfw/static/nsfw_model_manager.dart';
import 'package:ion/app/features/nsfw/static/shared/nsfw_isolate_functions.dart';
import 'package:ion/app/features/nsfw/static/shared/shared_nsfw_isolate.dart';
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
    );

class NsfwValidationService {
  NsfwValidationService({
    required this.detectorFactory,
    required this.videoCompressor,
    required this.videoInfoService,
  });

  final NsfwDetectorFactory detectorFactory;
  final VideoCompressor videoCompressor;
  final VideoInfoService videoInfoService;

  Completer<void>? _initCompleter;

  Future<Map<String, bool>> hasNsfwInMediaFiles(List<MediaFile> mediaFiles) async {
    final results = <String, bool>{};

    final imagePaths = mediaFiles.where(_isImageMedia).map((m) => m.path).toList();
    if (imagePaths.isNotEmpty) {
      final imageResults = await hasNsfwInImagePaths(imagePaths);
      results.addAll(imageResults);
    }

    // Check videos
    final videoFiles = _extractVideoFiles(mediaFiles);
    if (videoFiles.isNotEmpty) {
      final videoResults = await _hasNsfwInVideos(videoFiles);
      results.addAll(videoResults);
    }

    return results;
  }

  Future<Map<String, bool>> hasNsfwInImagePaths(List<String> imagePaths) async {
    final paths = imagePaths.where(_isImageExtension).toList();
    return _hasNsfwInImagePaths(paths);
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

  /// Ensures model is initialized in isolate (lazy init, thread-safe)
  Future<void> _ensureInitialized() async {
    // If already initialized or initialization in progress, wait
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    // Start initialization
    _initCompleter = Completer<void>();

    try {
      final modelPath = await NsfwModelManager.getModelPath();
      await sharedNsfwIsolate.compute(
        nsfwInitializeModelFn,
        [modelPath, detectorFactory.blockThreshold],
      );

      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Reset to allow retry
      rethrow;
    }
  }

  Future<Map<String, bool>> _hasNsfwInImagePaths(List<String> imagePaths) async {
    await _ensureInitialized();
    if (imagePaths.isEmpty) {
      return {};
    }

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

    final results = await sharedNsfwIsolate.compute(
      nsfwCheckImagesFn,
      [pathToBytes],
    );

    final finalResults = results.map(
      (path, result) => MapEntry(path, result.decision == NsfwDecision.block),
    );
    return finalResults;
  }

  List<MediaFile> _extractVideoFiles(List<MediaFile> mediaFiles) {
    return mediaFiles.where((m) {
      final mime = m.mimeType ?? '';
      return mime.startsWith('video/');
    }).toList();
  }

  Future<Map<String, bool>> _hasNsfwInVideos(List<MediaFile> videos) async {
    await _ensureInitialized();

    // Extract ALL thumbnails on main thread
    // final thumbnailBytes = <Uint8List>[];
    final thumbnailPathToBytes = <String, Uint8List>{}; // For isolate
    final thumbnailToVideo = <String, String>{};

    for (final video in videos) {
      final timestamps = await _buildTimestamps(video);

      for (final ts in timestamps) {
        try {
          final thumbMediaFile = await videoCompressor.getThumbnail(video, timestamp: ts);
          final bytes = await File(thumbMediaFile.path).readAsBytes();

          thumbnailPathToBytes[thumbMediaFile.path] = bytes; // Isolate needs this
          thumbnailToVideo[thumbMediaFile.path] = video.path; // We need this
          // thumbnailBytes.add(bytes);
        } catch (e, st) {
          Logger.error(e, message: 'NSFW video thumbnail validation failed', stackTrace: st);
        }
      }
    }

    if (thumbnailPathToBytes.isEmpty) return {};

    // Process ALL thumbnails in parallel using persistent isolate
    final results = await sharedNsfwIsolate.compute(
      nsfwCheckImagesFn,
      [thumbnailPathToBytes],
    );

    final videoResults = <String, bool>{};
    for (final entry in results.entries) {
      final thumbPath = entry.key;
      final isNsfw = entry.value.decision == NsfwDecision.block;
      final videoPath = thumbnailToVideo[thumbPath]!; // Look up parent

      if (isNsfw) {
        videoResults[videoPath] = true;
      } else {
        videoResults[videoPath] ??= false;
      }
    }

    return videoResults; // Map<video_path, isNsfw>
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
