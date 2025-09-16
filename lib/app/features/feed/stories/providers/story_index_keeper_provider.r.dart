// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'story_index_keeper_provider.r.g.dart';

/// A keepalive provider that maintains the current story index for each user.
/// This allows preserving the story position when navigating between different users' stories.
@Riverpod(keepAlive: true)
class StoryIndexKeeper extends _$StoryIndexKeeper {
  @override
  Map<String, int> build() {
    return <String, int>{};
  }

  void setStoryIndex(String userPubkey, int storyIndex) {
    state = {
      ...state,
      userPubkey: storyIndex,
    };
  }

  int getStoryIndex(String userPubkey) {
    return state[userPubkey] ?? 0;
  }
}
