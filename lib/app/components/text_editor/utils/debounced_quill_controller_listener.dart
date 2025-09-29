// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';

Stream<String> debouncedQuillControllerListener(
  QuillController controller, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  final streamController = StreamController<String>.broadcast();
  Timer? debounce;

  void listener() {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(duration, () {
      if (!streamController.isClosed) {
        streamController.add(controller.plainTextEditingValue.text);
      }
    });
  }

  streamController.onCancel = () {
    debounce?.cancel();
    controller.removeListener(listener);
    streamController.close(); // ensure no further adds
  };

  controller.addListener(listener);

  return streamController.stream;
}
