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
/// - On resume, schedules a one-shot for max(remaining, [minResumeDelay]), then returns to periodic cadence
/// - Cancels and rotates a [CancelToken] for in-flight async work on each pause/resume and tick
class PauseablePeriodicRunner {
  PauseablePeriodicRunner({
    required this.ref,
  });

  final Ref ref;
  Duration? _interval;
  Duration _minResumeDelay = const Duration(seconds: 30);
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
    Duration minResumeDelay = const Duration(seconds: 30),
    bool runImmediately = false,
  }) {
    _interval = interval;
    _minResumeDelay = minResumeDelay;
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

        // On resume: rotate cancel token and schedule a one-shot for max(remaining, minResumeDelay)
        replaceCancelToken();
        var delay = _remainingUntilNext ?? _interval!;
        if (delay < _minResumeDelay) {
          delay = _minResumeDelay;
        }
        _remainingUntilNext = null;
        _scheduleOneShot(delay);
      } else {
        // Background/inactive: capture remaining time, stop timers, cancel in-flight work.
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

        if (!_cancelToken.isCancelled) {
          _cancelToken.cancel();
        }
      }
    });
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

  void _scheduleOneShot(Duration delay) {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _oneShotTimer?.cancel();
    _oneShotTimer = Timer(delay, () {
      _fire();
      _schedulePeriodic();
    });
    _nextFireAt = DateTime.now().add(delay);
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
