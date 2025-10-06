// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:video_player/video_player.dart';

void useToggleVideoOnLifecycleChange(WidgetRef ref, VideoPlayerController? playerController) {
  ref.listen(appLifecycleProvider, (_, current) {
    if (!ref.context.mounted || playerController == null) return;

    // Only resume playback when *this* route is currently active (on top).
    final isOnTop = ref.context.isCurrentRoute;

    switch (current) {
      case AppLifecycleState.resumed:
        if (isOnTop && playerController.value.isInitialized && !playerController.value.isPlaying) {
          playerController.play();
        }

      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        if (playerController.value.isInitialized && playerController.value.isPlaying) {
          playerController.pause();
        }
    }
  });
}
