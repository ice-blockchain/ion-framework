// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/stories/providers/story_pause_provider.r.dart';

const Key storyGestureHandlerKey = Key('story_gesture_handler');

Key storyGestureKeyFor(String pubkey) => Key('story_gesture_$pubkey');

class StoryGestureHandler extends HookConsumerWidget {
  const StoryGestureHandler({
    required this.child,
    required this.onTapLeft,
    required this.onTapRight,
    this.viewerPubkey,
    super.key,
  });

  final Widget child;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final String? viewerPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapPosition = useState<Offset?>(null);
    final isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => tapPosition.value = details.globalPosition,
      onTap: () {
        if (isKeyboardVisible) {
          FocusScope.of(context).unfocus();
          return;
        }

        final screenWidth = MediaQuery.sizeOf(context).width;
        final isLeftSide = (tapPosition.value?.dx ?? 0) < screenWidth / 2;

        if (isLeftSide) {
          onTapLeft();
        } else {
          onTapRight();
        }
      },
      onLongPressStart: (_) {
        ref.read(storyPauseControllerProvider.notifier).paused = true;
        ref.read(storyOverlayContentVisibilityControllerProvider.notifier).visible = false;
      },
      onLongPressEnd: (_) {
        ref.read(storyPauseControllerProvider.notifier).paused = false;
        ref.read(storyOverlayContentVisibilityControllerProvider.notifier).visible = true;
      },
      child: child,
    );
  }
}
