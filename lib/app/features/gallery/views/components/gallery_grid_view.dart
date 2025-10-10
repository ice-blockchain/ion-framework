// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/gallery/data/models/gallery_state.f.dart';
import 'package:ion/app/features/gallery/views/components/components.dart';
import 'package:ion/app/features/gallery/views/components/media/add_media_cell.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';

class GalleryGridView extends ConsumerWidget {
  const GalleryGridView({
    required this.galleryState,
    required this.showSelectionBadge,
    required this.isNeedFilterVideoByFormat,
    this.type = MediaPickerType.common,
    this.showCameraCell = true,
    super.key,
  });

  static const _offsetBetweenItems = 4.0;
  static const _itemsPerRow = 3;

  final GalleryState galleryState;
  final MediaPickerType type;
  final bool showSelectionBadge;
  final bool showCameraCell;
  final bool isNeedFilterVideoByFormat;

  int _getIndexOffset(bool hasLimitedPermission) {
    var offset = 0;
    if (showCameraCell) offset += 1; // +1 for CameraCell
    if (hasLimitedPermission) offset += 1; // +1 for AddCell

    return offset;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLimitedPermission = ref.watch(hasLimitedPermissionProvider(Permission.photos));
    final indexOffset = _getIndexOffset(hasLimitedPermission);
    final totalCount = galleryState.mediaData.length + indexOffset;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _itemsPerRow,
        crossAxisSpacing: _offsetBetweenItems.s,
        mainAxisSpacing: _offsetBetweenItems.s,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          var currentIndex = index;

          if (showCameraCell && index == 0) {
            return CameraCell(
              type: type,
              isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
            );
          } else if (showCameraCell) {
            currentIndex -= 1;
          }

          if (hasLimitedPermission && currentIndex == 0) {
            return AddMediaCell(type: type);
          } else if (hasLimitedPermission && currentIndex > 0) {
            currentIndex -= 1;
          }

          final mediaData = galleryState.mediaData[currentIndex];
          return GalleryGridCell(
            key: ValueKey(mediaData.path),
            mediaFile: mediaData,
            isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
            type: type,
            showSelectionBadge: showSelectionBadge,
          );
        },
        childCount: totalCount,
      ),
    );
  }
}
