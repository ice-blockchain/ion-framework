// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'story_pause_provider.r.g.dart';

@riverpod
class StoryPauseController extends _$StoryPauseController {
  @override
  bool build() => false;

  set paused(bool value) => state = value;
}

@riverpod
class StoryOverlayContentVisibilityController extends _$StoryOverlayContentVisibilityController {
  @override
  bool build() => true;

  set visible(bool value) => state = value;
}

@riverpod
class StoryMenuController extends _$StoryMenuController {
  @override
  bool build() => false;

  set menuOpen(bool value) => state = value;
}
