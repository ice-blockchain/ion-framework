// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Best-effort protection against third-party overlay windows (TYPE_APPLICATION_OVERLAY)
/// occluding the app while a sensitive flow is running.
///
/// On Android 12+ this calls `Window.setHideOverlayWindows(true)`.
/// On other platforms / versions this is a no-op.
class IonOverlayGuard {
  IonOverlayGuard._();

  static const MethodChannel _channel = MethodChannel('io.ion.app/overlay_guard');

  static Future<bool> isSupported() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Hides or shows third-party overlay windows on top of the current Activity.
  ///
  /// Best-effort: failures are swallowed.
  static Future<void> setHideOverlayWindows({required bool hide}) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('setHideOverlayWindows', <String, Object?>{
        'hide': hide,
      });
    } catch (_) {
      // ignore: best-effort
    }
  }

  /// Runs [fn] while overlay windows are hidden. Always restores the prior state
  /// on completion.
  static Future<T> runWithHiddenOverlays<T>(Future<T> Function() fn) async {
    if (!Platform.isAndroid) {
      return fn();
    }

    await setHideOverlayWindows(hide: true);
    try {
      return await fn();
    } finally {
      await setHideOverlayWindows(hide: false);
    }
  }
}
