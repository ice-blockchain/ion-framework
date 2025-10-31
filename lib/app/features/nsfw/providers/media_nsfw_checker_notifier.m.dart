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
    @Default({}) Map<String, bool?> nsfwResults,
    @Default(false) bool isFinalCheckInProcess,
  }) = _MediaNsfwState;

  const MediaNsfwState._();

  bool get isEmpty => nsfwResults.isEmpty;
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
    // 1. Make a new list containing only the requested media files, keeping values from previous checks if they exist
    // to prevent one more redundant extra check for the same file.
    final previousResults = state.nsfwResults;
    final currentResults = <String, bool?>{};
    for (final mediaFile in mediaFiles) {
      final path = mediaFile.path;
      currentResults[path] = previousResults[path]; // NSFW result or null
    }
    state = state.copyWith(nsfwResults: currentResults);

    // 2. Get list of file paths that need checking (paths with null value)
    final needToCheckPaths = currentResults.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();

    if (needToCheckPaths.isEmpty) {
      return;
    }

    // 3. Filter original mediaFiles to only those needing check
    final needToCheckMediaFiles =
        mediaFiles.where((file) => needToCheckPaths.contains(file.path)).toList();

    final nsfwValidationService = await ref.read(nsfwValidationServiceProvider.future);
    final nsfwCheckResults = await nsfwValidationService.hasNsfwInMediaFiles(needToCheckMediaFiles);

    // 4. Update the current results with the new checks results
    for (final nsfwCheckResult in nsfwCheckResults.entries) {
      currentResults[nsfwCheckResult.key] = nsfwCheckResult.value;
    }
    state = state.copyWith(nsfwResults: currentResults);
  }

  Future<bool> getFinalNsfwResult() async {
    // Set final check in process
    state = state.copyWith(isFinalCheckInProcess: true);

    final hasPendingChecks = state.nsfwResults.values.any((bool? isNsfw) => isNsfw == null);
    if (!hasPendingChecks) {
      final hasNsfw = state.nsfwResults.values.any((bool? isNsfw) => isNsfw! == true);
      // Reset final check in process
      state = state.copyWith(isFinalCheckInProcess: false);
      return hasNsfw;
    }

    final completer = Completer<bool>();

    listenSelf((_, next) {
      final hasPendingChecks = next.nsfwResults.values.any((bool? isNsfw) => isNsfw == null);
      if (!hasPendingChecks && !completer.isCompleted) {
        final hasNsfw = next.nsfwResults.values.any((bool? isNsfw) => isNsfw! == true);
        completer.complete(hasNsfw);
      }
    });

    final result = await completer.future;
    state = state.copyWith(isFinalCheckInProcess: false);
    return result;
  }
}
