// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/animation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/stories/providers/camera_capture_provider.r.dart';

final Duration maxRecordingDuration = 60.seconds;

typedef RecordingProgressResult = (
  Duration recordingDuration,
  double recordingProgress,
);

/// Tracks recording progress and automatically stops recording when time runs out.
RecordingProgressResult useRecordingProgress(
  WidgetRef ref, {
  required bool isRecording,
}) {
  final animationController = useAnimationController(
    duration: maxRecordingDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
  final currentRecordingDuration = useState<Duration>(Duration.zero);

  useEffect(
    () {
      if (isRecording) {
        animationController.forward(from: 0);
      } else {
        animationController.reset();
        currentRecordingDuration.value = Duration.zero;
      }

      void listener() {
        final updatedDuration = maxRecordingDuration * animationController.value;
        currentRecordingDuration.value = updatedDuration;

        if (animationController.isCompleted) {
          ref.read(cameraCaptureControllerProvider.notifier).stopVideoRecording();
        }
      }

      animationController.addListener(listener);

      return () => animationController.removeListener(listener);
    },
    [isRecording, animationController],
  );

  return (
    currentRecordingDuration.value,
    animationController.value,
  );
}
