// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topic_tooltip_visibility_notifier.r.g.dart';

@riverpod
class TopicTooltipVisibilityNotifier extends _$TopicTooltipVisibilityNotifier {
  @override
  bool build() => false;

  void show() => state = true;

  void hide() => state = false;
}
