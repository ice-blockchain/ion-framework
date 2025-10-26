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
    // Cleanup when provider is disposed (though keepAlive: true means it won't auto-dispose)
    ref.onDispose(() {
      print('🧹 MediaNsfwParallelChecker disposed - cleaning up resources');
      // Add any cleanup logic here if needed
    });

    return const MediaNsfwState();
  }

  Future<void> addMediaListCheck(List<MediaFile> mediaFiles) async {
    print('🔥Instance hash: ${identityHashCode(this)}');
    print('Fresh state: $state');

    // Create new state with all media files as pending checks
    final newChecks = <MediaFile, bool?>{...state.checks};
    for (final mediaFile in mediaFiles) {
      newChecks[mediaFile] = null;
    }
    state = state.copyWith(checks: newChecks);
    print('🔥Pending states added: ${state.checks.length}');

    print('🔥DATETIME: ${DateTime.now()}');
    final nsfwValidationService = await ref.read(nsfwValidationServiceProvider.future);
    final hasNsfw = await nsfwValidationService.hasNsfwInMediaFiles(mediaFiles);

    print('🔥Has NSFW: $hasNsfw');
    print('🔥DATETIME: ${DateTime.now()} state: $state');

    if (hasNsfw) {
      final newChecks = <MediaFile, bool?>{...state.checks};
      for (final mediaFile in mediaFiles) {
        newChecks[mediaFile] = true;
      }
      state = state.copyWith(checks: newChecks);
      print('🔥States updated after NSFW check: $newChecks}');
    } else {
      final newChecks = <MediaFile, bool?>{...state.checks};
      for (final mediaFile in mediaFiles) {
        newChecks[mediaFile] = false;
      }
      state = state.copyWith(checks: newChecks);
      print('🔥States updated after no NSFW check: $newChecks}');
    }
  }

  Future<bool> getNsfwCheckValueOrWaitUntil() async {
    print('🔥Instance hash: ${identityHashCode(this)}');
    print('🔥Final checks started');

    // Set final check in process
    state = state.copyWith(isFinalCheckInProcess: true);

    print('🔥Current State: $state');
    final hasPendingChecks = state.checks.values.any((bool? isNsfw) => isNsfw == null);
    print('🔥Has pending checks: $hasPendingChecks');
    if (!hasPendingChecks) {
      final hasNsfw = state.checks.values.any((bool? isNsfw) => isNsfw! == true);
      print(
        '🔥State: $state',
      );
      print(
        '🔥No pending checks, returning result: $hasNsfw',
      );
      // Reset final check in process
      state = state.copyWith(isFinalCheckInProcess: false);
      return hasNsfw;
    }
    print('🔥STILL PENDING CHECKS');

    final completer = Completer<bool>();

    listenSelf((_, next) {
      print('🔥ListenSelf: New state: $next');
      final hasPendingChecks = next.checks.values.any((bool? isNsfw) => isNsfw == null);
      print('🔥ListenSelf: Has pending checks: $hasPendingChecks');
      if (!hasPendingChecks && !completer.isCompleted) {
        print('🔥ListenSelf: Completing completer');
        completer.complete(next.checks.values.any((bool? isNsfw) => isNsfw! == true));
      }
    });

    final result = await completer.future;
    print('🔥ListenSelf: Result: $result');
    return result;
  }
}
