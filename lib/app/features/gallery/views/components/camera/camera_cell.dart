// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_sheets.dart';
import 'package:ion/app/features/gallery/data/models/camera_state.f.dart';
import 'package:ion/app/features/gallery/providers/camera_provider.r.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/gallery/views/components/camera/camera.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class CameraCell extends HookConsumerWidget {
  const CameraCell({
    required this.type,
    required this.isNeedFilterVideoByFormat,
    super.key,
  });

  final MediaPickerType type;
  final bool isNeedFilterVideoByFormat;

  static double get cellHeight => 120.0.s;
  static double get cellWidth => 122.0.s;

  Future<void> _openCamera(
    BuildContext context,
    GalleryNotifier galleryNotifier,
  ) async {
    final mediaFile = await GalleryCameraRoute(mediaPickerType: type).push<MediaFile?>(context);

    if (mediaFile != null) {
      await galleryNotifier.addCapturedMediaFileToGallery(mediaFile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(Permission.camera));
    final cameraControllerNotifier = ref.read(cameraControllerNotifierProvider.notifier);
    final shouldOpenCamera = useState(false);

    ref
      ..listen<bool>(
        hasPermissionProvider(Permission.camera),
        (previous, next) async {
          final wasResumed = await cameraControllerNotifier.handlePermissionChange(
            hasPermission: next,
          );

          if (wasResumed) {
            shouldOpenCamera.value = true;
          }
        },
      )
      ..listen<CameraState>(
        cameraControllerNotifierProvider,
        (previous, next) async {
          await next.whenOrNull(
            ready: (_, __, ___) async {
              /// Open camera only if the camera is ready
              /// and also if the camera was not opened before
              /// it's prevents opening the camera multiple times
              final isTransitonReady = previous is! CameraReady && next is CameraReady;

              if (shouldOpenCamera.value && isTransitonReady) {
                shouldOpenCamera.value = false;

                await _openCamera(
                  context,
                  ref.read(
                    galleryNotifierProvider(
                      type: type,
                      isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
                    ).notifier,
                  ),
                );
              }
            },
          );
        },
      );

    return PermissionAwareWidget(
      permissionType: Permission.camera,
      onGranted: () async {
        await ref.read(cameraControllerNotifierProvider).maybeWhen(
              ready: (_, __, ___) => _openCamera(
                context,
                ref.read(
                  galleryNotifierProvider(
                    type: type,
                    isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
                  ).notifier,
                ),
              ),
              orElse: () {
                shouldOpenCamera.value = true;
                cameraControllerNotifier.resumeCamera();
              },
            );
      },
      requestDialog: const PermissionRequestSheet(permission: Permission.camera),
      settingsDialog: SettingsRedirectSheet.fromType(context, Permission.camera),
      builder: (context, onPressed) {
        return SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: GestureDetector(
            onTap: onPressed,
            child: !hasPermission
                ? const CameraPlaceholderWidget()
                : ref.watch(cameraControllerNotifierProvider).maybeWhen(
                      ready: (controller, _, ___) {
                        return CameraPreviewWidget(
                          key: ValueKey(controller),
                          controller: controller,
                        );
                      },
                      orElse: () => const CameraPlaceholderWidget(),
                    ),
          ),
        );
      },
    );
  }
}
