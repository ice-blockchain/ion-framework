// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';

Stream<String> debouncedQuillControllerListener(
  QuillController controller, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  late StreamController<String> streamController;
  Timer? debounce;

  late void Function() listener;

  streamController = StreamController<String>.broadcast(
    onCancel: () {
      debounce?.cancel();
      controller.removeListener(listener);
      streamController.close(); // ensure no further adds
    },
  );

  listener = () {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(duration, () {
      if (!streamController.isClosed) {
        streamController.add(controller.plainTextEditingValue.text);
      }
    });
  };

  controller.addListener(listener);

  return streamController.stream;
}
