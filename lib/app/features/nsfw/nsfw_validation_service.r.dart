// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/nsfw_detector_factory.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nsfw_validation_service.r.g.dart';

@riverpod
NsfwValidationService nsfwValidationService(Ref ref) => NsfwValidationService(
      detectorFactory: ref.read(nsfwDetectorFactoryProvider),
    );

class NsfwValidationService {
  const NsfwValidationService({required this.detectorFactory});

  final NsfwDetectorFactory detectorFactory;

  bool _isImageExtension(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  bool isImageMedia(MediaFile media) {
    final mime = media.mimeType ?? '';
    if (mime.startsWith('image/')) return true;
    return _isImageExtension(media.path);
  }

  Future<bool> hasNsfwInMediaFiles(List<MediaFile> mediaFiles) async {
    final imagePaths = mediaFiles.where(isImageMedia).map((m) => m.path).toList();
    return _hasNsfwInImagePaths(imagePaths);
  }

  Future<bool> hasNsfwInImagePaths(List<String> imagePaths) async {
    final paths = imagePaths.where(_isImageExtension).toList();
    return _hasNsfwInImagePaths(paths);
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
}
