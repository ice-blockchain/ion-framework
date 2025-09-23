// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:video_player/video_player.dart';

void useToggleVideoOnRouteChange(VideoPlayerController? playerController) {
  useRoutePresence(
    onBecameInactive: () {
      if (playerController != null && playerController.value.isPlaying) {
        playerController.pause();
      }
    },
    onBecameActive: () {
      if (playerController != null &&
          playerController.value.isInitialized &&
          !playerController.value.isPlaying) {
        playerController.play();
      }
    },
  );
}
