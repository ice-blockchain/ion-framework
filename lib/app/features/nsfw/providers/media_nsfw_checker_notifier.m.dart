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

  Future<void> checkMediaForNsfw(List<MediaFile> mediaFiles) async {
    if (mediaFiles.isEmpty && !state.isEmpty) {
      state = state.copyWith(nsfwResults: <String, bool?>{});
      return;
    }

    // 1. Remove all NSFW files from previous checks
    final previousSafeResults =
        Map.fromEntries(state.nsfwResults.entries.where((entry) => entry.value != true));

    // 2. Add all new files to the pending state, and keep the rest as is
    final checkStateWithPending = <String, bool?>{...previousSafeResults};
    for (final mediaFile in mediaFiles) {
      final path = mediaFile.path;
      if (checkStateWithPending.containsKey(path)) {
        continue;
      }
      checkStateWithPending[path] = null;
    }

    // 3. Create new state with new pending checks added
    state = state.copyWith(nsfwResults: checkStateWithPending);
    // Logs removed for cleanliness

    // 4. Get list of files that need checking (paths with null value)
    final needToCheckPaths = checkStateWithPending.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();

    if (needToCheckPaths.isEmpty) {
      return;
    }

    // 5. Filter original mediaFiles to only those needing check
    final needToCheckMediaFiles =
        mediaFiles.where((file) => needToCheckPaths.contains(file.path)).toList();

    final nsfwValidationService = await ref.read(nsfwValidationServiceProvider.future);
    final nsfwCheckResults = await nsfwValidationService.hasNsfwInMediaFiles(needToCheckMediaFiles);

    // 6. Update the state with the new checks results
    final updatedResults = <String, bool?>{...state.nsfwResults};
    for (final path in needToCheckPaths) {
      if (nsfwCheckResults.containsKey(path)) {
        updatedResults[path] = nsfwCheckResults[path];
      }
      // If result is missing, keep as null (pending/failed) - don't default to false
    }
    state = state.copyWith(nsfwResults: updatedResults);
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
