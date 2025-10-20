// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';

typedef CloseOverlayMenuCallback = void Function({bool animate});

class OverlayMenuCloseSignal extends ValueNotifier<int> {
  OverlayMenuCloseSignal() : super(0);

  void trigger() => value++;
}
