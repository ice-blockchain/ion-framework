// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/nsfw/nsfw_validation_service.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_nsfw_parallel_checker.m.freezed.dart';
part 'media_nsfw_parallel_checker.m.g.dart';

@freezed
class MediaNsfwState with _$MediaNsfwState {
  const factory MediaNsfwState({
    @Default({}) Map<MediaFile, bool?> checks,
    @Default(false) bool isFinalCheckInProcess,
  }) = _MediaNsfwState;
}

@riverpod
class MediaNsfwParallelChecker extends _$MediaNsfwParallelChecker {
  @override
  MediaNsfwState build() {
    return const MediaNsfwState();
  }

  Future<void> addMediaListCheck(List<MediaFile> mediaFiles) async {
    // 1. Remove all NSFW files from previous checks
    final hasNotNsfwFromPreviousChecks =
        Map.fromEntries(state.checks.entries.where((entry) => entry.value != true));

    // 2. Add all new files to the pending state, and keep the rest as is
    final updatedChecksWithNewPending = <MediaFile, bool?>{...hasNotNsfwFromPreviousChecks};
    for (final mediaFile in mediaFiles) {
      if (updatedChecksWithNewPending.containsKey(mediaFile)) continue;
      updatedChecksWithNewPending[mediaFile] = null;
    }

    // 3. Create new state with new pending checks added
    state = state.copyWith(checks: updatedChecksWithNewPending);

    final needToCheckMediaFiles = updatedChecksWithNewPending.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();

    if (needToCheckMediaFiles.isEmpty) {
      return;
    }

    final nsfwValidationService = await ref.read(nsfwValidationServiceProvider.future);
    final hasNsfw = await nsfwValidationService.hasNsfwInMediaFiles(needToCheckMediaFiles);

    // 4. Update the state with the new checks results
    final newResultChecks = <MediaFile, bool?>{...state.checks};
    for (final mediaFile in needToCheckMediaFiles) {
      newResultChecks[mediaFile] = hasNsfw;
    }
    state = state.copyWith(checks: newResultChecks);
  }

  Future<bool> getNsfwCheckValueOrWaitUntil() async {
    // Set final check in process
    state = state.copyWith(isFinalCheckInProcess: true);

    final hasPendingChecks = state.checks.values.any((bool? isNsfw) => isNsfw == null);
    if (!hasPendingChecks) {
      final hasNsfw = state.checks.values.any((bool? isNsfw) => isNsfw! == true);
      // Reset final check in process
      state = state.copyWith(isFinalCheckInProcess: false);
      return hasNsfw;
    }

    final completer = Completer<bool>();

    listenSelf((_, next) {
      final hasPendingChecks = next.checks.values.any((bool? isNsfw) => isNsfw == null);
      if (!hasPendingChecks && !completer.isCompleted) {
        completer.complete(next.checks.values.any((bool? isNsfw) => isNsfw! == true));
      }
    });

    final result = await completer.future;
    state = state.copyWith(isFinalCheckInProcess: false);

    return result;
  }
}
