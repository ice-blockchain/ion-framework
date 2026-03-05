// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sharing_intent/shared_content.dart';
import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_media_stream_provider.r.g.dart';

@Riverpod(keepAlive: true)
Stream<SharedContent> sharedMediaStream(Ref ref) {
  final controller = StreamController<SharedContent>.broadcast();

  void emitFromMedia(List<SharedMediaFile> files) {
    final textFiles = files.where((f) => f.type == SharedMediaType.text && f.path.isNotEmpty);
    final imageFiles = files.where((f) => f.type == SharedMediaType.image && f.path.isNotEmpty);

    for (final file in textFiles) {
      controller.add(SharedText(file.path));
    }

    if (imageFiles.isNotEmpty) {
      controller.add(SharedImage([imageFiles.first.path]));
    }
  }

  // Delay to allow the plugin's native side to fully attach to the activity
  // and read the launch intent before we query it.
  Future<void>.delayed(const Duration(seconds: 1)).then((_) {
    return ReceiveSharingIntent.instance.getInitialMedia();
  }).then((List<SharedMediaFile> value) {
    if (value.isNotEmpty) {
      emitFromMedia(value);
      ReceiveSharingIntent.instance.reset();
    }
  }).catchError((Object error) {
    Logger.error(error, message: 'sharedMediaStream getInitialMedia');
  });

  final subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
    emitFromMedia,
    onError: (Object error) {
      Logger.error(error, message: 'sharedMediaStream getMediaStream');
    },
  );

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
}
