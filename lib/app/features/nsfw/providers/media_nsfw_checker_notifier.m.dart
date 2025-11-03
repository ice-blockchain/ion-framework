// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/nsfw/models/media_check_data.dart';
import 'package:ion/app/features/nsfw/models/nsfw_check_result.f.dart';
import 'package:ion/app/features/nsfw/nsfw_validation_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_nsfw_checker_notifier.m.freezed.dart';
part 'media_nsfw_checker_notifier.m.g.dart';

@freezed
class MediaNsfwState with _$MediaNsfwState {
  const factory MediaNsfwState({
    @Default({}) Map<String, MediaCheckData> mediaChecks,
    @Default(false) bool loading,
  }) = _MediaNsfwState;

  const MediaNsfwState._();

  bool get isEmpty => mediaChecks.isEmpty;
}

@riverpod
class MediaNsfwCheckerNotifier extends _$MediaNsfwCheckerNotifier {
  @override
  MediaNsfwState build() {
    return const MediaNsfwState();
  }

  void resetNsfwResults() {
    state = const MediaNsfwState();
  }

  Future<void> checkMediaForNsfw(List<MediaFile> mediaFiles) async {
    // Remove media not in the new list
    final updatedChecks = Map<String, MediaCheckData>.from(state.mediaChecks)
      ..removeWhere((path, _) => !mediaFiles.any((file) => file.path == path));

    // Add new media files, which was not in the state
    final newMedia = <MediaFile>[];
    for (final file in mediaFiles) {
      if (!updatedChecks.containsKey(file.path)) {
        updatedChecks[file.path] = MediaCheckData(
          mediaFile: file,
          completer: Completer<bool>(),
        );
        newMedia.add(file);
      }
    }

    state = state.copyWith(mediaChecks: updatedChecks);

    if (newMedia.isEmpty) return;

    final nsfwService = await ref.read(nsfwValidationServiceProvider.future);

    try {
      // Perform batch check
      final batchResults = await nsfwService.hasNsfwInMediaFiles(newMedia);

      // Complete completers
      for (final entry in batchResults.entries) {
        final path = entry.key;
        final value = entry.value;

        final checkData = updatedChecks[path];
        if (checkData != null && !checkData.completer.isCompleted) {
          checkData.completer.complete(value);
        }
      }
    } catch (e, st) {
      // As the failure is for batch, we need to complete all completers with the error
      for (final file in newMedia) {
        final checkData = updatedChecks[file.path];
        if (checkData != null && !checkData.completer.isCompleted) {
          checkData.completer.completeError(e);
        }
      }

      Logger.error(e, message: 'NSFW validation failed', stackTrace: st);
    }
  }

  Future<NsfwCheckResult> hasNsfwMedia() async {
    state = state.copyWith(loading: true);

    final futures = state.mediaChecks.values.map((c) => c.completer.future).toList();

    try {
      final results = await Future.wait(futures);
      final hasNsfw = results.any((r) => r == true);

      return NsfwCheckResult.success(hasNsfw: hasNsfw);
    } catch (e, st) {
      Logger.error(e, message: 'NSFW validation failed', stackTrace: st);

      unawaited(_retryNsfwCheck());

      return NsfwCheckResult.failure(error: e);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _retryNsfwCheck() async {
    final mediaFiles = state.mediaChecks.values.map((d) => d.mediaFile).toList();
    _resetMediaChecks();

    await checkMediaForNsfw(mediaFiles);
  }

  void _resetMediaChecks() {
    state = state.copyWith(mediaChecks: {});
  }
}
