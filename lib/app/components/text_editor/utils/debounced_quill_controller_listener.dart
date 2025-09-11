import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';

Stream<String> debouncedQuillControllerListener(
  QuillController controller, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  late StreamController<String> streamController;
  Timer? debounce;

  streamController = StreamController<String>.broadcast(
    onCancel: () => debounce?.cancel(),
  );

  controller.addListener(() {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(duration, () {
      streamController.add(controller.plainTextEditingValue.text);
    });
  });

  return streamController.stream;
}
