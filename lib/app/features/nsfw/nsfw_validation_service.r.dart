// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/nsfw_detector_factory.r.dart';
import 'package:ion/app/features/nsfw/static/shared/nsfw_isolate_functions.dart';
import 'package:ion/app/features/nsfw/static/shared/shared_nsfw_isolate.dart';
import 'package:ion/app/features/nsfw/static/nsfw_model_manager.dart';
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

  Future<bool> hasNsfwInMediaFiles(List<MediaFile> mediaFiles) async {
    final imagePaths = mediaFiles.where(_isImageMedia).map((m) => m.path).toList();
    final hasNsfwInImages = await hasNsfwInImagePaths(imagePaths);
    if (hasNsfwInImages) return true;

    final videoFiles = _extractVideoFiles(mediaFiles);
    if (videoFiles.isEmpty) return false;

    final hasNsfwInVideos = await _hasNsfwInVideos(videoFiles);
    if (hasNsfwInVideos) return true;

    return false;
  }

  Future<bool> hasNsfwInImagePaths(List<String> imagePaths) async {
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
      return _initCompleter!.future;
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

  Future<bool> _hasNsfwInImagePaths(List<String> imagePaths) async {
    await _ensureInitialized();
    if (imagePaths.isEmpty) return false;

    // Read all image bytes in parallel
    final imageBytesListFutures = imagePaths.map((path) async {
      try {
        final file = File(path);
        return await file.readAsBytes();
      } catch (e) {
        return null;
      }
    }).toList();

    final imageBytesListNullable = await Future.wait(imageBytesListFutures);
    final imageBytesList =
        imageBytesListNullable.where((bytes) => bytes != null).map((bytes) => bytes!).toList();

    if (imageBytesList.isEmpty) return false;

    // Use persistent isolate directly
    final results = await sharedNsfwIsolate.compute(
      nsfwCheckImagesFn,
      [imageBytesList],
    );

    return results.any((r) => r.decision == NsfwDecision.block);
  }

  List<MediaFile> _extractVideoFiles(List<MediaFile> mediaFiles) {
    return mediaFiles.where((m) {
      final mime = m.mimeType ?? '';
      return mime.startsWith('video/');
    }).toList();
  }

  Future<bool> _hasNsfwInVideos(List<MediaFile> videos) async {
    return _hasNsfwInVideosParallel(videos);
  }

  // Extract thumbnails on main thread, process in isolates
  Future<bool> _hasNsfwInVideosParallel(List<MediaFile> videos) async {
    await _ensureInitialized();

    // Extract ALL thumbnails on main thread
    final thumbnailBytes = <Uint8List>[];

    for (final video in videos) {
      final timestamps = await _buildTimestamps(video);
      for (final ts in timestamps) {
        try {
          final thumbMediaFile = await videoCompressor.getThumbnail(video, timestamp: ts);
          final bytes = await File(thumbMediaFile.path).readAsBytes();
          thumbnailBytes.add(bytes);
        } catch (e, st) {
          Logger.error(e, message: 'NSFW video thumbnail validation failed', stackTrace: st);
        }
      }
    }

    if (thumbnailBytes.isEmpty) {
      return false;
    }

    // Process ALL thumbnails in parallel using persistent isolate
    final results = await sharedNsfwIsolate.compute(
      nsfwCheckImagesFn,
      [thumbnailBytes],
    );

    return results.any((r) => r.decision == NsfwDecision.block);
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
