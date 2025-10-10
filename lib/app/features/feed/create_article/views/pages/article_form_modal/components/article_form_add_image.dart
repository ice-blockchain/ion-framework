// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ion/app/extensions/riverpod.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_sheets.dart';
import 'package:ion/app/features/feed/create_article/views/components/article_image_container.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class ArticleFormAddImage extends HookConsumerWidget {
  const ArticleFormAddImage({
    required this.selectedImage,
    required this.selectedImageUrl,
    super.key,
  });

  final ValueNotifier<MediaFile?> selectedImage;
  final ValueNotifier<String?> selectedImageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaService = ref.watch(mediaServiceProvider);

    ref.displayErrorsForState<ImageProcessorStateError>(
      imageProcessorNotifierProvider(ImageProcessingType.articleCover),
    );

    return PermissionAwareWidget(
      requestId: 'create_article_image',
      permissionType: Permission.photos,
      onGranted: () async {
        if (context.mounted) {
          final mediaFiles = await MediaPickerRoute(
            isNeedFilterVideoByFormat: false,
            maxSelection: 1,
            mediaPickerType: MediaPickerType.image,
          ).push<List<MediaFile>>(context);

          if (mediaFiles != null && mediaFiles.isNotEmpty && context.mounted) {
            selectedImageUrl.value = null;

            final cropUiSettings = mediaService.buildCropImageUiSettings(
              context,
              aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
            );

            await ref
                .read(imageProcessorNotifierProvider(ImageProcessingType.articleCover).notifier)
                .process(
                  assetId: mediaFiles.first.path,
                  cropUiSettings: cropUiSettings,
                );
          }
        }
      },
      requestDialog: const PermissionRequestSheet(permission: Permission.photos),
      settingsDialog: SettingsRedirectSheet.fromType(context, Permission.photos),
      builder: (context, onPressed) => ArticleImageContainer(
        selectedImage: selectedImage.value,
        selectedImageUrl: selectedImageUrl.value,
        onPressed: onPressed,
        onClearImage: () {
          selectedImage.value = null;
          selectedImageUrl.value = null;
        },
      ),
    );
  }
}
