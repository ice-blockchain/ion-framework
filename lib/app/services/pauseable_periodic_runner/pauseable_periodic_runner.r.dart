// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pauseable_periodic_runner.r.g.dart';

/// A reusable periodic runner that:
/// - Fires a callback on a fixed [interval]
/// - Pauses when app goes to background/inactive and remembers remaining time
/// - On resume, schedules a one‑shot after the remaining time and then restores periodic cadence (no cancel on resume)
/// - Rotates a [CancelToken] only when starting a new tick (not on resume)
class PauseablePeriodicRunner {
  PauseablePeriodicRunner({
    required this.ref,
  });

  final Ref ref;
  Duration? _interval;
  void Function(CancelToken)? _onTick;

  Timer? _periodicTimer;
  Timer? _oneShotTimer;
  DateTime? _nextFireAt;
  Duration? _remainingUntilNext;

  CancelToken _cancelToken = CancelToken();

  /// Cancels the current token (if not already cancelled) and returns a new one.
  CancelToken replaceCancelToken() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
    return _cancelToken = CancelToken();
  }

  void start({
    required Duration interval,
    required void Function(CancelToken) onTick,
    bool runImmediately = false,
  }) {
    _interval = interval;
    _onTick = onTick;

    _schedulePeriodic();
    if (runImmediately) {
      _fire();
    }

    // Listen to app lifecycle changes and pause/resume accordingly.
    ref.listen<AppLifecycleState>(appLifecycleProvider, (previous, next) {
      if (next == AppLifecycleState.resumed) {
        // No-op until start() is called.
        if (_onTick == null || _interval == null) return;

        resume();
      } else {
        pause();
      }
    });
  }

  /// Explicitly pause the runner (used by lifecycle or sensitive flows like passkeys).
  /// Captures remaining time, stops timers
  void pause() {
    final now = DateTime.now();
    if (_nextFireAt != null) {
      var remaining = _nextFireAt!.difference(now);
      if (remaining.isNegative) remaining = Duration.zero;
      _remainingUntilNext = remaining;
    } else {
      _remainingUntilNext = _interval;
    }

    _periodicTimer?.cancel();
    _periodicTimer = null;
    _oneShotTimer?.cancel();
    _oneShotTimer = null;
  }

  void resume() {
    if (_onTick == null || _interval == null) return;

    // Determine how long to wait until next tick; default to a full interval if unknown.
    final delay = _remainingUntilNext ?? _interval!;
    _remainingUntilNext = null;

    // Ensure no leftover timers.
    _oneShotTimer?.cancel();
    _periodicTimer?.cancel();

    if (delay <= Duration.zero) {
      // If we're at/over the boundary, fire now and restart periodic cadence.
      _fire();
      _schedulePeriodic();
    } else {
      // Resume by waiting the remaining delay, then fire once and restore periodic cadence.
      _oneShotTimer = Timer(delay, () {
        _fire();
        _schedulePeriodic();
      });
      _nextFireAt = DateTime.now().add(delay);
    }
  }

  void _fire() {
    final cb = _onTick;
    if (cb != null) {
      cb(replaceCancelToken());
    }
  }

  void _schedulePeriodic() {
    if (_interval == null) return;
    final interval = _interval!;
    _oneShotTimer?.cancel();
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      _nextFireAt = DateTime.now().add(interval);
      _fire();
    });
    _nextFireAt = DateTime.now().add(interval);
  }

  Future<void> dispose() async {
    _periodicTimer?.cancel();
    _oneShotTimer?.cancel();
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
  }
}

@riverpod
PauseablePeriodicRunner pauseablePeriodicRunner(Ref ref) {
  final pauseablePeriodicRunner = PauseablePeriodicRunner(ref: ref);
  ref.onDispose(() async {
    await pauseablePeriodicRunner.dispose();
  });
  return pauseablePeriodicRunner;
}
