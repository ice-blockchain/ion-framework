// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sharing_intent/shared_content.dart';
import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_media_stream_provider.r.g.dart';

/// Converts raw [SharedMediaFile] list into typed [SharedContent] objects.
List<SharedContent> parseSharedMediaFiles(List<SharedMediaFile> files) {
  final results = <SharedContent>[];

  final textFiles = files.where(
    (f) => (f.type == SharedMediaType.text || f.type == SharedMediaType.url) && f.path.isNotEmpty,
  );
  final imageFiles = files.where((f) => f.type == SharedMediaType.image && f.path.isNotEmpty);

  for (final file in textFiles) {
    results.add(SharedText(file.path));
  }

  if (imageFiles.isNotEmpty) {
    results.add(SharedImage([imageFiles.first.path]));
  }

  return results;
}

/// Streams shared content arriving while the app is already running
/// (warm start / app in background). For cold-start initial media,
/// see [ReceiveSharingIntentListener] which calls getInitialMedia()
/// once the app is ready.
@Riverpod(keepAlive: true)
Stream<SharedContent> sharedMediaStream(Ref ref) {
  final controller = StreamController<SharedContent>.broadcast();

  final subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
    (files) {
      for (final content in parseSharedMediaFiles(files)) {
        controller.add(content);
      }
    },
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
