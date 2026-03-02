// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_text_stream_provider.r.g.dart';

@Riverpod(keepAlive: true)
Stream<String> sharedTextStream(Ref ref) {
  final controller = StreamController<String>.broadcast();

  void emitTextFromMedia(List<SharedMediaFile> files) {
    for (final file in files) {
      if (file.type == SharedMediaType.text && file.path.isNotEmpty) {
        controller.add(file.path);
      }
    }
  }

  ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
    if (value.isNotEmpty) {
      emitTextFromMedia(value);
      ReceiveSharingIntent.instance.reset();
    }
  });

  final subscription = ReceiveSharingIntent.instance.getMediaStream().listen(emitTextFromMedia);

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
}
