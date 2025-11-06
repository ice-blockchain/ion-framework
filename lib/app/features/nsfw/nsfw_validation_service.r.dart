// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/models/video_thumbnail.dart';
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

  // Combined validation: images + videos in single isolate call
  Future<Map<String, bool>> hasNsfwInMediaFiles(List<MediaFile> mediaFiles) async {
    final imageFiles = mediaFiles.where(_isImageMedia).toList();
    final videoFiles = _extractVideoFiles(mediaFiles);

    final thumbnails = await _generateVideoThumbnails(videoFiles);
    final mediaBytesToCheck =
        await _prepareMediaBytes(imageFiles: imageFiles, thumbnails: thumbnails);

    if (mediaBytesToCheck.isEmpty) return {};

    final nsfwResults = await _checkMediaBytesForNsfw(mediaBytesToCheck);

    return _buildMediaCheckResultsMap(
      nsfwResults: nsfwResults,
      images: imageFiles,
      videos: videoFiles,
      thumbnails: thumbnails,
    );
  }

  Future<Map<String, bool>> hasNsfwInImagePaths(List<String> paths) async {
    if (paths.isEmpty) {
      return {};
    }

    final imagePaths = paths.where(_isImageExtension).toList();

    final imageFiles = imagePaths.map((path) => MediaFile(path: path)).toList();
    final pathToBytes = await _prepareMediaBytes(imageFiles: imageFiles);

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

  Future<List<VideoThumbnail>> _generateVideoThumbnails(List<MediaFile> videos) async {
    final thumbnails = <VideoThumbnail>[];

    for (final video in videos) {
      final timestamps = await _buildTimestamps(video);

      for (final ts in timestamps) {
        final thumbMedia = await videoCompressor.getThumbnail(video, timestamp: ts);
        final bytes = await File(thumbMedia.path).readAsBytes();

        thumbnails.add(
          VideoThumbnail(
            path: thumbMedia.path,
            bytes: bytes,
            videoPath: video.path,
          ),
        );
      }
    }

    return thumbnails;
  }

  Future<Map<String, Uint8List>> _prepareMediaBytes({
    List<MediaFile>? imageFiles,
    List<VideoThumbnail>? thumbnails,
  }) async {
    assert(
      (imageFiles != null && imageFiles.isNotEmpty) ||
          (thumbnails != null && thumbnails.isNotEmpty),
      'Both imageFiles and thumbnails cannot be null or empty',
    );

    final mediaBytes = <String, Uint8List>{};

    if (imageFiles != null) {
      for (final image in imageFiles) {
        final bytes = await File(image.path).readAsBytes();
        mediaBytes[image.path] = bytes;
      }
    }

    if (thumbnails != null) {
      for (final t in thumbnails) {
        mediaBytes[t.path] = t.bytes;
      }
    }

    return mediaBytes;
  }

  Future<Map<String, NsfwResult>> _checkMediaBytesForNsfw(
    Map<String, Uint8List> bytesToCheck,
  ) async {
    final modelPath = await nsfwModelManager.getModelPath();

    final nsfwResults = await compute(
      nsfwCheckAllMediaOneShotFn,
      [modelPath, detectorFactory.blockThreshold, bytesToCheck],
    );

    return nsfwResults;
  }

  Map<String, bool> _buildMediaCheckResultsMap({
    required Map<String, NsfwResult> nsfwResults,
    required List<VideoThumbnail> thumbnails,
    required List<MediaFile> images,
    required List<MediaFile> videos,
  }) {
    final finalResults = <String, bool>{};

    // Direct images
    for (final image in images) {
      final decision = nsfwResults[image.path]?.decision;
      finalResults[image.path] = decision == NsfwDecision.block;
    }

    // Group thumbnails by their video
    final thumbsByVideo = <String, List<VideoThumbnail>>{};
    for (final thumb in thumbnails) {
      thumbsByVideo.putIfAbsent(thumb.videoPath, () => []).add(thumb);
    }

    // Aggregate per video
    for (final video in videos) {
      final relatedThumbs = thumbsByVideo[video.path];
      if (relatedThumbs == null || relatedThumbs.isEmpty) {
        finalResults[video.path] = false;
        continue;
      }

      final hasNsfw = relatedThumbs.any(
        (t) => nsfwResults[t.path]?.decision == NsfwDecision.block,
      );

      finalResults[video.path] = hasNsfw;
    }

    return finalResults;
  }
}
