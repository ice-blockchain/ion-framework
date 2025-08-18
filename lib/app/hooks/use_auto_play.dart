// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_player/video_player.dart';

void useAutoPlay(VideoPlayerController? controller) {
  useEffect(
    () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller?.play();
      });

      return () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller?.pause();
        });
      };
    },
    [controller],
  );
}
