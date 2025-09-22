// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:video_player/video_player.dart';

void useToggleVideoOnLifecycleChange(WidgetRef ref, VideoPlayerController? playerController) {
  ref.listen(appLifecycleProvider, (_, current) {
    if (!ref.context.mounted || playerController == null) return;

    if (current == AppLifecycleState.resumed) {
      playerController.play();
    } else if (current == AppLifecycleState.paused || current == AppLifecycleState.hidden) {
      playerController.pause();
    }
  });
}
