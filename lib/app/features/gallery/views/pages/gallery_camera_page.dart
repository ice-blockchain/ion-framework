// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/stories/data/models/camera_capture_state.f.dart';
import 'package:ion/app/features/feed/stories/hooks/use_recording_progress.dart';
import 'package:ion/app/features/feed/stories/providers/camera_capture_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/camera/camera_idle_preview.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/camera/custom_camera_preview.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/controls/camera_capture_button.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/controls/camera_recording_indicator.dart';
import 'package:ion/app/features/gallery/data/models/camera_state.f.dart';
import 'package:ion/app/features/gallery/providers/camera_provider.r.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/utils/future.dart';

class GalleryCameraPage extends HookConsumerWidget {
  const GalleryCameraPage({
    required this.type,
    super.key,
  });

  final MediaPickerType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shutterAnimationController = useAnimationController(duration: 50.milliseconds);
    final shutterAnimation = useMemoized(
      () => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: shutterAnimationController,
          curve: Curves.easeIn,
        ),
      ),
      [shutterAnimationController],
    );

    useEffect(
      () {
        void animationStatusListener(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            shutterAnimationController.reverse();
          }
        }

        shutterAnimationController.addStatusListener(animationStatusListener);

        return () {
          shutterAnimationController.removeStatusListener(animationStatusListener);
        };
      },
      [shutterAnimationController],
    );
    final cameraState = ref.watch(cameraControllerNotifierProvider);

    ref.listen<CameraCaptureState>(
      cameraCaptureControllerProvider,
      (_, next) {
        next.whenOrNull(
          saved: (file) {
            if (context.mounted) context.pop(file);
          },
        );
      },
    );

    final isRecording = cameraState.maybeWhen(
      ready: (_, isRecording, __) => isRecording,
      orElse: () => false,
    );

    final (recordingDuration, recordingProgress) = useRecordingProgress(
      ref,
      isRecording: isRecording,
    );

    final captureController = ref.read(cameraCaptureControllerProvider.notifier);
    final isCameraReady = cameraState is CameraReady;

    final capturePhotoAction =
        isCameraReady ? () => _takePhoto(captureController, shutterAnimationController) : null;
    final startVideoAction = isCameraReady ? captureController.startVideoRecording : null;
    final stopVideoAction = isCameraReady ? captureController.stopVideoRecording : null;

    final (onCapturePhoto, onRecordingStart, onRecordingStop) = switch (type) {
      MediaPickerType.image => (capturePhotoAction, null, null),
      MediaPickerType.video => (null, startVideoAction, stopVideoAction),
      MediaPickerType.common => (capturePhotoAction, startVideoAction, stopVideoAction),
    };

    return Scaffold(
      backgroundColor: context.theme.appColors.primaryText,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            cameraState.maybeWhen(
              ready: (controller, _, __) => CustomCameraPreview(controller: controller),
              orElse: () => const CenteredLoadingIndicator(),
            ),
            if (isRecording)
              CameraRecordingIndicator(recordingDuration: recordingDuration)
            else
              CameraIdlePreview(
                showGalleryButton: false,
                onGallerySelected: (_) async {},
              ),
            IgnorePointer(
              child: AnimatedBuilder(
                builder: (context, widget) {
                  return Opacity(
                    opacity: shutterAnimation.value,
                    child: widget,
                  );
                },
                animation: shutterAnimationController,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
            Positioned.fill(
              bottom: 16.0.s,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CameraCaptureButton(
                  isRecording: isRecording,
                  recordingProgress: recordingProgress,
                  onCapturePhoto: onCapturePhoto,
                  onRecordingStart: onRecordingStart,
                  onRecordingStop: onRecordingStop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(
    CameraCaptureController captureController,
    AnimationController shutterAnimationController,
  ) async {
    unawaited(shutterAnimationController.forward(from: 0));
    await captureController.takePhoto();
  }
}
