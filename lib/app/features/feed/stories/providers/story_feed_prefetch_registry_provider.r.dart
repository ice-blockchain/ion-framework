// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'story_feed_prefetch_registry_provider.r.g.dart';

@riverpod
class StoryFeedPrefetchRegistry extends _$StoryFeedPrefetchRegistry {
  @override
  Set<String> build(String pubkey) => <String>{};

  void add(String storyId) {
    if (storyId.isEmpty || state.contains(storyId)) return;
    state = {...state, storyId};
  }

  void remove(String storyId) {
    if (!state.contains(storyId)) return;
    final next = {...state}..remove(storyId);
    state = next;
  }

  void replaceWith(Iterable<String> storyIds) {
    final next = storyIds.toSet()..removeWhere((id) => id.isEmpty);
    if (setEquals(next, state)) return;
    state = next;
  }
}
