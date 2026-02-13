// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

/// Global state tracker for passkey dialogs.
/// Simpler than using a Riverpod provider since it doesn't require context or ref.
class GlobalPasskeyDialogState {
  GlobalPasskeyDialogState._();

  static bool _isShowing = false;
  static Completer<void>? _dismissCompleter;

  /// Whether a passkey dialog is currently showing
  static bool get isShowing => _isShowing;

  /// Mark the dialog as shown
  static void setShowing() {
    _isShowing = true;
    _dismissCompleter = Completer<void>();
  }

  /// Mark the dialog as dismissed
  static void setDismissed() {
    _isShowing = false;
    if (_dismissCompleter != null && !_dismissCompleter!.isCompleted) {
      _dismissCompleter!.complete();
    }
    _dismissCompleter = null;
  }

  /// Wait for the dialog to be dismissed (if showing)
  static Future<void> waitForDismissal() async {
    if (!_isShowing) return;
    await _dismissCompleter?.future;
  }
}
