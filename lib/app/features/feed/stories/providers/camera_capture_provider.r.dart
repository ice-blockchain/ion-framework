// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:ion/app/features/feed/stories/data/models/camera_capture_state.f.dart';
import 'package:ion/app/features/gallery/providers/camera_provider.r.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_capture_provider.r.g.dart';

@riverpod
class CameraCaptureController extends _$CameraCaptureController {
  @override
  CameraCaptureState build() => const CameraCaptureState.initial();

  Future<void> takePhoto() async {
    Logger.info('[ImageCapture] CameraCaptureController.takePhoto');
    final camera = ref.read(cameraControllerNotifierProvider.notifier);

    try {
      final xFile = await camera.takePicture();
      Logger.info('[ImageCapture] CameraCaptureController.takePhoto got xFile');

      if (xFile == null) {
        state = const CameraCaptureState.error(message: 'Failed to take photo.');
        return;
      }

      final mediaFile = await ref.read(mediaServiceProvider).saveImageToGallery(File(xFile.path));
      Logger.info('[ImageCapture] CameraCaptureController.takePhoto saved file to gallery');

      if (mediaFile == null) {
        state = const CameraCaptureState.error(message: 'Failed to save photo.');
        return;
      }

      ref.invalidate(latestGalleryPreviewProvider);
      state = CameraCaptureState.saved(file: mediaFile);
    } catch (e) {
      state = CameraCaptureState.error(message: 'Error taking photo: $e');
    }
  }

  Future<void> startVideoRecording() async {
    await ref.read(cameraControllerNotifierProvider.notifier).startVideoRecording();
    state = const CameraCaptureState.recording();
  }

  Future<void> stopVideoRecording() async {
    final camera = ref.read(cameraControllerNotifierProvider.notifier);
    final xFile = await camera.stopVideoRecording();

    if (xFile == null) {
      state = const CameraCaptureState.error(message: 'Failed to stop video recording.');
      return;
    }

    final mediaFile = await ref.read(mediaServiceProvider).saveVideoToGallery(File(xFile.path));

    if (mediaFile == null) {
      state = const CameraCaptureState.error(message: 'Failed to save video.');
      return;
    }

    state = CameraCaptureState.saved(file: mediaFile);
  }

  Future<void> toggleFlash() => ref.read(cameraControllerNotifierProvider.notifier).toggleFlash();

  void reset() => state = const CameraCaptureState.initial();
}
