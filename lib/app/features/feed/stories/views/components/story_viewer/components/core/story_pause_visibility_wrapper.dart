// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/stories/providers/story_pause_provider.r.dart';

class StoryPauseVisibilityWrapper extends ConsumerWidget {
  const StoryPauseVisibilityWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaused = ref.watch(storyPauseControllerProvider);

    return AnimatedOpacity(
      opacity: isPaused ? 0 : 1,
      duration: const Duration(milliseconds: 150),
      child: child,
    );
  }
}
