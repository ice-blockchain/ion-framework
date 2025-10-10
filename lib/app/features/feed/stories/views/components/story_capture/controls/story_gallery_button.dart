// SPDX-License-Identifier: ice License 1.0
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_sheets.dart';
import 'package:ion/app/features/feed/stories/views/components/story_capture/controls/story_control_button.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class StoryGalleryButton extends HookConsumerWidget {
  const StoryGalleryButton({required this.onSelected, super.key});
  final Future<void> Function(MediaFile) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionAwareWidget(
      permissionType: Permission.photos,
      onGranted: () async {
        final files = await MediaPickerRoute(
          maxSelection: 1,
          showCameraCell: false,
          isNeedFilterVideoByFormat: true,
        ).push<List<MediaFile>>(context);
        if (files == null || files.isEmpty) return;
        await onSelected(files.first);
      },
      requestDialog: const PermissionRequestSheet(permission: Permission.photos),
      settingsDialog: SettingsRedirectSheet.fromType(context, Permission.photos),
      builder: (context, onPressed) {
        final preview = ref.watch(latestGalleryPreviewProvider).valueOrNull;

        return StoryControlButton(
          onPressed: onPressed,
          iconPadding: preview == null ? null : 0.0.s,
          icon: preview == null
              ? Assets.svg.iconGalleryOpen.icon(
                  color: context.theme.appColors.onPrimaryAccent,
                )
              : Image(
                  width: 36.0.s,
                  height: 36.0.s,
                  fit: BoxFit.cover,
                  image: AssetEntityImageProvider(
                    preview,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(300),
                  ),
                ),
        );
      },
    );
  }
}
