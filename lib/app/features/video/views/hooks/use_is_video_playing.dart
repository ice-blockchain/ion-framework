// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/hooks/use_route_presence.dart';
import 'package:video_player/video_player.dart';

ValueNotifier<bool> useIsVideoPlaying(WidgetRef ref, VideoPlayerController playerController) {
  final isPlaying = useState(playerController.value.isPlaying);

  useEffect(
    () {
      void listener() {
        isPlaying.value = playerController.value.isPlaying;
      }

      playerController.addListener(listener);
      return () => playerController.removeListener(listener);
    },
    [playerController],
  );

  useRoutePresence(
    onBecameInactive: () {
      if (playerController.value.isPlaying) {
        playerController.pause();
      }
    },
    onBecameActive: () {
      if (playerController.value.isInitialized && !playerController.value.isPlaying) {
        playerController.play();
      }
    },
  );

  ref.listen(appLifecycleProvider, (_, current) {
    if (!ref.context.mounted) return;

    if (current == AppLifecycleState.resumed) {
      playerController.play();
    } else if (current == AppLifecycleState.paused || current == AppLifecycleState.hidden) {
      playerController.pause();
    }
  });

  return isPlaying;
}
