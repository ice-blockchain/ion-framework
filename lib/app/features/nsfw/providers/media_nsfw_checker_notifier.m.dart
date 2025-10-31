// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/nsfw/nsfw_validation_service.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_nsfw_checker_notifier.m.freezed.dart';
part 'media_nsfw_checker_notifier.m.g.dart';

@freezed
class MediaNsfwState with _$MediaNsfwState {
  const factory MediaNsfwState({
    @Default({}) Map<String, Completer<bool>> nsfwCompleters,
    @Default(false) bool loading,
  }) = _MediaNsfwState;

  const MediaNsfwState._();

  bool get isEmpty => nsfwCompleters.isEmpty;
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
    // Remove completers for media files that are not in the new list
    final currentCompleters = Map<String, Completer<bool>>.from(state.nsfwCompleters)
      ..removeWhere((path, _) => !mediaFiles.any((file) => file.path == path));

    // Create new completers for new media files
    final newMedia = <MediaFile>[];
    for (final file in mediaFiles) {
      if (!currentCompleters.containsKey(file.path)) {
        currentCompleters[file.path] = Completer<bool>();
        newMedia.add(file);
      }
    }

    state = state.copyWith(nsfwCompleters: currentCompleters);

    if (newMedia.isEmpty) return;

    final nsfwService = await ref.read(nsfwValidationServiceProvider.future);
    final batchResults = await nsfwService.hasNsfwInMediaFiles(newMedia);

    // Complete completers for new media files
    for (final entry in batchResults.entries) {
      final path = entry.key;
      final value = entry.value;

      final completer = currentCompleters[path];
      if (completer != null && !completer.isCompleted) {
        completer.complete(value);
      }
    }
  }

  Future<bool> hasNsfwMedia() async {
    state = state.copyWith(loading: true);

    final futures = state.nsfwCompleters.values.map((c) => c.future).toList();
    final results = await Future.wait(futures);
    final hasNsfw = results.any((r) => r == true);

    state = state.copyWith(loading: false);

    return hasNsfw;
  }
}
