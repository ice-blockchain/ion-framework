// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'show_close_button_provider.r.g.dart';

@riverpod
class ShowCloseButton extends _$ShowCloseButton {
  @override
  bool build() {
    return true;
  }

  void setShowCloseButton({required bool showCloseButton}) {
    if (state != showCloseButton) {
      state = showCloseButton;
    }
  }
}
