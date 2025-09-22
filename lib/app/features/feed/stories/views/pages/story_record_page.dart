// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_sheets.dart';
import 'package:ion/app/features/feed/stories/data/models/camera_capture_state.f.dart';
import 'package:ion/app/features/feed/stories/data/models/story_preview_result.f.dart';
import 'package:ion/app/features/feed/stories/hooks/use_recording_progress.dart';
import 'package:ion/app/features/feed/stories/providers/camera_capture_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/media_editing_service.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/camera/camera_idle_preview.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/camera/custom_camera_preview.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/controls/camera_capture_button.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/controls/camera_recording_indicator.dart';
import 'package:ion/app/features/gallery/data/models/camera_state.f.dart';
import 'package:ion/app/features/gallery/providers/camera_provider.r.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/media_service/banuba_service.r.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/future.dart';
import 'package:path/path.dart' as path;

class StoryRecordPage extends HookConsumerWidget {
  const StoryRecordPage({super.key});

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
    final isRecording = cameraState.maybeWhen(
      ready: (_, recording, __) => recording,
      orElse: () => false,
    );

    final (recordingDuration, recordingProgress) =
        useRecordingProgress(ref, isRecording: isRecording);

    final isCameraReady = cameraState is CameraReady;
    final captureController = ref.watch(cameraCaptureControllerProvider.notifier);

    ref
      ..listen<CameraCaptureState>(
        cameraCaptureControllerProvider,
        (previous, next) => _handleCameraCaptureState(context, ref, next),
      )
      ..listen<ImageProcessorState>(
        imageProcessorNotifierProvider(ImageProcessingType.story),
        (previous, next) => _handleImageProcessorState(context, ref, next),
      );

    Future<void> onGallerySelected(MediaFile file) => _handleGallerySelection(context, ref, file);

    return PermissionAwareWidget(
      permissionType: Permission.camera,
      onGranted: () => ref.read(cameraControllerNotifierProvider.notifier).resumeCamera(),
      requestDialog: const PermissionRequestSheet(permission: Permission.camera),
      settingsDialog: SettingsRedirectSheet.fromType(context, Permission.camera),
      builder: (context, _) => Scaffold(
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
                  onGallerySelected: onGallerySelected,
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
                    onCapturePhoto: isCameraReady
                        ? () => _takePhoto(captureController, shutterAnimationController)
                        : null,
                    onRecordingStart: isCameraReady ? captureController.startVideoRecording : null,
                    onRecordingStop: isCameraReady ? captureController.stopVideoRecording : null,
                  ),
                ),
              ),
            ],
          ),
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

  Future<void> _handleCameraCaptureState(
    BuildContext context,
    WidgetRef ref,
    CameraCaptureState state,
  ) async {
    await state.whenOrNull(
      saved: (file) async {
        final mediaType = MediaType.fromMimeType(file.mimeType ?? '');

        if (mediaType == MediaType.video) {
          final edited = await ref.read(mediaEditingServiceProvider).edit(
                file,
                resumeCamera: false,
                videoCoverSelectionEnabled: false,
              );

          if (edited != null && edited != file.path && context.mounted) {
            final result = await StoryPreviewRoute(
              path: edited,
              mimeType: file.mimeType,
              fromEditor: true,
              originalFilePath: file.path,
            ).push<StoryPreviewResult>(context);

            if (result != null && context.mounted) {
              await _handleStoryPreviewResult(context, ref, result);
            }
          }
          await ref.read(cameraControllerNotifierProvider.notifier).resumeCamera();
        } else if (mediaType == MediaType.image) {
          await ref
              .read(
                imageProcessorNotifierProvider(ImageProcessingType.story).notifier,
              )
              .process(
                assetId: file.path,
                cropUiSettings: ref.read(mediaServiceProvider).buildCropImageUiSettings(
                  context,
                  aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
                ),
              );
        }
      },
    );
  }

  Future<void> _handleImageProcessorState(
    BuildContext context,
    WidgetRef ref,
    ImageProcessorState state,
  ) async {
    await state.whenOrNull(
      processed: (file) async {
        final edited = await ref
            .read(mediaEditingServiceProvider)
            .editExternalPhoto(file.path, resumeCamera: false);

        if (edited != null && edited != file.path) {
          // Banuba returns edited image as png so we need to compress it to webp
          final compressedImage = await ref.read(imageCompressorProvider).compress(
                MediaFile(path: edited),
                settings: ImageCompressionSettings(
                  quality: ImageProcessingType.story.config.quality,
                ),
              );

          if (!context.mounted) return;

          final result = await StoryPreviewRoute(
            path: compressedImage.path,
            mimeType: compressedImage.mimeType,
            fromEditor: true,
            originalFilePath: file.path,
          ).push<StoryPreviewResult>(context);

          if (result != null && context.mounted) {
            await _handleStoryPreviewResult(context, ref, result);
          }
        }
        await ref.read(cameraControllerNotifierProvider.notifier).resumeCamera();
      },
    );
  }

  Future<void> _handleGallerySelection(
    BuildContext context,
    WidgetRef ref,
    MediaFile file,
  ) async {
    final mediaType = MediaType.fromMimeType(file.mimeType ?? '');

    if (mediaType == MediaType.video) {
      final edited = await ref.read(mediaEditingServiceProvider).edit(
            file,
            resumeCamera: false,
            videoCoverSelectionEnabled: false,
          );

      if (edited != null && edited != file.path && context.mounted) {
        final filePath = path.isAbsolute(file.path)
            ? file.path
            : await ref.read(assetFilePathProvider(file.path).future);

        if (!context.mounted) return;

        final result = await StoryPreviewRoute(
          path: edited,
          mimeType: file.mimeType,
          fromEditor: true,
          originalFilePath: filePath,
        ).push<StoryPreviewResult>(context);

        if (result != null && context.mounted) {
          await _handleStoryPreviewResult(context, ref, result);
        }
      }
      await ref.read(cameraControllerNotifierProvider.notifier).resumeCamera();
    } else if (mediaType == MediaType.image) {
      await ref
          .read(
            imageProcessorNotifierProvider(ImageProcessingType.story).notifier,
          )
          .process(
            assetId: file.path,
            cropUiSettings: ref.read(mediaServiceProvider).buildCropImageUiSettings(
              context,
              aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
            ),
          );
    }
  }

  Future<void> _handleStoryPreviewResult(
    BuildContext context,
    WidgetRef ref,
    StoryPreviewResult result,
  ) async {
    await result.when(
      edited: (originalPath, mimeType) async {
        final mediaType = MediaType.fromMimeType(mimeType);
        final banubaService = ref.read(banubaServiceProvider);

        String? editedPath;

        if (mediaType == MediaType.image) {
          editedPath = await banubaService.editPhoto(originalPath);
        } else if (mediaType == MediaType.video) {
          final result = await banubaService.editVideo(
            originalPath,
            coverSelectionEnabled: false,
          );
          editedPath = result?.newPath;
        }

        if (editedPath != null && context.mounted) {
          final previewResult = await StoryPreviewRoute(
            path: editedPath,
            mimeType: mimeType,
            fromEditor: true,
            originalFilePath: originalPath,
          ).push<StoryPreviewResult>(context);

          // Recursively handle results if user wants to edit again
          if (previewResult != null && context.mounted) {
            await _handleStoryPreviewResult(context, ref, previewResult);
          }
        }
      },
      published: () {
        if (context.mounted) {
          context.pop();
        }
      },
      cancelled: () {},
    );
  }
}
