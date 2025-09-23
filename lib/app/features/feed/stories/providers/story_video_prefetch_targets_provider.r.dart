// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'story_video_prefetch_targets_provider.r.g.dart';

@riverpod
class StoryVideoPrefetchTargets extends _$StoryVideoPrefetchTargets {
  @override
  Set<String> build(String pubkey) => <String>{};

  void replaceWith(Iterable<String> storyIds) {
    final next = storyIds.toSet()..removeWhere((id) => id.isEmpty);
    if (next.length == state.length && state.containsAll(next)) {
      return;
    }
    state = next;
  }

  void clear() {
    if (state.isEmpty) {
      return;
    }
    state = <String>{};
  }
}
