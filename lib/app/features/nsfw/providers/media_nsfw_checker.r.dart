// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/models/media_check_data.dart';
import 'package:ion/app/features/nsfw/models/nsfw_check_result.f.dart';
import 'package:ion/app/features/nsfw/nsfw_validation_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_nsfw_checker.r.g.dart';

@Riverpod(keepAlive: true)
Future<MediaNsfwChecker> mediaNsfwChecker(Ref ref) async => MediaNsfwChecker(
      nsfwValidationService: await ref.read(nsfwValidationServiceProvider.future),
    );

class MediaNsfwChecker {
  MediaNsfwChecker({
    required this.nsfwValidationService,
  });

  final NsfwValidationService nsfwValidationService;

  final Map<String, MediaCheckData> _mediaChecks = {};

  bool get isEmpty => _mediaChecks.isEmpty;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void reset() {
    _mediaChecks.clear();
    _isLoading = false;
  }

  Future<void> checkMediaForNsfw(List<MediaFile> mediaFiles) async {
    // Remove media checks which are not in the new actual list
    _mediaChecks.removeWhere((path, _) => !mediaFiles.any((file) => file.path == path));

    // Add new media files, which was not in the state, for validation purposes
    final newMedia = <MediaFile>[];
    for (final file in mediaFiles) {
      if (!_mediaChecks.containsKey(file.path)) {
        _mediaChecks[file.path] = MediaCheckData(
          mediaFile: file,
          completer: Completer<bool>(),
        );
        newMedia.add(file);
      }
    }

    if (newMedia.isEmpty) {
      return;
    }

    try {
      // Perform batch check
      final batchResults = await nsfwValidationService.hasNsfwInMediaFiles(newMedia);

      // Complete completers
      for (final entry in batchResults.entries) {
        final checkData = _mediaChecks[entry.key];
        if (checkData != null && !checkData.completer.isCompleted) {
          checkData.completer.complete(entry.value);
        }
      }
    } catch (e, st) {
      Logger.error(e, message: 'NSFW validation batch failed', stackTrace: st);

      // As the failure is for batch, we need to complete all completers with the error
      for (final file in newMedia) {
        final checkData = _mediaChecks[file.path];
        if (checkData != null && !checkData.completer.isCompleted) {
          checkData.completer.completeError(e);
        }
      }
    }
  }

  Future<NsfwCheckResult> hasNsfwMedia() async {
    _isLoading = true;

    final futures = _mediaChecks.values.map((c) => c.completer.future).toList();

    try {
      final results = await Future.wait(futures);
      final hasNsfw = results.any((r) => r == true);

      return NsfwCheckResult.success(hasNsfw: hasNsfw);
    } catch (e, st) {
      Logger.error(e, message: 'NSFW validation failed', stackTrace: st);
      unawaited(_retryNsfwCheck());

      return NsfwCheckResult.failure(error: e);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _retryNsfwCheck() async {
    if (_mediaChecks.isEmpty) return;

    final mediaFiles = _mediaChecks.values.map((d) => d.mediaFile).toList();

    _mediaChecks.clear();
    await checkMediaForNsfw(mediaFiles);
  }
}
