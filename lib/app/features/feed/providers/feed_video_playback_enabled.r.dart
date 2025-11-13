// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_video_playback_enabled.r.g.dart';

@Riverpod(keepAlive: true)
class FeedVideoPlaybackEnabledNotifier extends _$FeedVideoPlaybackEnabledNotifier {
  @override
  bool build() {
    return true;
  }

  void enablePlayback() {
    state = true;
  }

  void disablePlayback() {
    state = false;
  }
}
