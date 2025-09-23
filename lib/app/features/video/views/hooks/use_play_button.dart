// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:video_player/video_player.dart';

({bool showPlayButton, VoidCallback onTogglePlay}) usePlayButton(
  WidgetRef ref,
  VideoPlayerController? playerController,
) {
  final isPlaying = useState(playerController?.value.isPlaying ?? false);
  final isTapped = useState(false);

  // Toggle [isPlaying] state when video player controller state changes
  useEffect(
    () {
      void listener() {
        isPlaying.value = playerController?.value.isPlaying ?? false;
      }

      playerController?.addListener(listener);
      return () => playerController?.removeListener(listener);
    },
    [playerController],
  );

  // Reset [isTapped] when the video changes
  useOnInit(
    () => isTapped.value = false,
    [playerController],
  );

  return (
    /// Show play button if the video is not playing and user has tapped on the video.
    ///
    /// Tracking [isTapped] because before auto-play starts, video is not playing for a couple of frames.
    showPlayButton: !isPlaying.value && isTapped.value,

    /// Toggle play/pause state of the video
    onTogglePlay: () {
      if (playerController == null || !playerController.value.isInitialized) return;

      isTapped.value = true;

      if (playerController.value.isPlaying) {
        playerController.pause();
      } else {
        playerController.play();
      }
    }
  );
}
