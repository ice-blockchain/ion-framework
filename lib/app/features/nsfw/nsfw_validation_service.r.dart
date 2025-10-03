// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/nsfw_detector_factory.r.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nsfw_validation_service.r.g.dart';

@riverpod
NsfwValidationService nsfwValidationService(Ref ref) => NsfwValidationService(
      detectorFactory: ref.read(nsfwDetectorFactoryProvider),
      videoCompressor: ref.read(videoCompressorProvider),
    );

class NsfwValidationService {
  const NsfwValidationService({required this.detectorFactory, required this.videoCompressor});

  final NsfwDetectorFactory detectorFactory;
  final VideoCompressor videoCompressor;

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

  Future<bool> _hasNsfwInImagePaths(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return false;

    final detector = await detectorFactory.create();
    try {
      for (final path in imagePaths) {
        try {
          final bytes = await File(path).readAsBytes();
          final result = await detector.classifyBytes(bytes);
          if (result.decision != NsfwDecision.allow) {
            return true;
          }
        } catch (_) {}
      }
      return false;
    } finally {
      detector.dispose();
    }
  }

  List<MediaFile> _extractVideoFiles(List<MediaFile> mediaFiles) {
    return mediaFiles.where((m) {
      final mime = m.mimeType ?? '';
      return mime.startsWith('video/');
    }).toList();
  }

  Future<bool> _hasNsfwInVideos(List<MediaFile> videos) async {
    final detector = await detectorFactory.create();
    try {
      for (final video in videos) {
        final timestamps = await _buildTimestamps(video);
        for (final ts in timestamps) {
          try {
            final thumbMediaFile = await videoCompressor.getThumbnail(video, timestamp: ts);
            final bytes = await File(thumbMediaFile.path).readAsBytes();
            final result = await detector.classifyBytes(bytes);
            if (result.decision != NsfwDecision.allow) {
              return true;
            }
          } catch (_) {}
        }
      }
      return false;
    } finally {
      detector.dispose();
    }
  }

  Future<List<String>> _buildTimestamps(MediaFile video) async {
    final durationMs =
        video.duration ?? (await videoCompressor.getVideoDuration(video.path))?.inMilliseconds;
    if (durationMs == null || durationMs <= 0) {
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
