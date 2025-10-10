// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/upload_limit_modal_type.dart';
import 'package:ion/app/features/chat/views/pages/upload_limit_reached_modal/upload_limit_reached_modal.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/gallery/providers/media_selection_provider.r.dart';
import 'package:ion/app/features/gallery/views/components/components.dart';
import 'package:ion/app/features/gallery/views/components/duration_badge.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class GalleryGridCell extends ConsumerWidget {
  const GalleryGridCell({
    required this.mediaFile,
    required this.isNeedFilterVideoByFormat,
    required this.showSelectionBadge,
    this.type = MediaPickerType.common,
    super.key,
  });

  final MediaFile mediaFile;
  final MediaPickerType type;
  final bool showSelectionBadge;
  final bool isNeedFilterVideoByFormat;

  static double get cellHeight => 120.0.s;

  static double get cellWidth => 122.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(mediaSelectionStateProvider(mediaFile.path));
    final assetEntityAsync = ref.watch(assetEntityProvider(mediaFile.path));
    final maxNumberOfMediaSelected = ref.watch(
      mediaSelectionNotifierProvider
          .select((state) => state.selectedMedia.length >= state.maxSelection),
    );
    final isDisabled = !selectionState.isSelected && maxNumberOfMediaSelected;

    final maxVideoDurationInSeconds = ref.watch(
      mediaSelectionNotifierProvider.select((state) => state.maxVideoDurationInSeconds),
    );

    return SizedBox(
      width: cellWidth,
      height: cellHeight,
      child: assetEntityAsync.maybeWhen(
        data: (asset) {
          if (asset == null) {
            return const ShimmerLoadingCell();
          }

          return GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    final isSelectedAssetValid = _validateAsset(
                      asset: asset,
                      context: context,
                      maxVideoDurationInSeconds: maxVideoDurationInSeconds,
                    );
                    if (isSelectedAssetValid) {
                      ref.read(mediaSelectionNotifierProvider.notifier).toggleSelection(
                            mediaFile.path,
                            type: type,
                            isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
                          );
                    }
                  },
            child: Image(
              image: AssetEntityImageProvider(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(300),
              ),
              fit: BoxFit.cover,
              frameBuilder: (_, Widget child, int? frame, bool wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return Opacity(
                    opacity: isDisabled ? 0.5 : 1.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        child,
                        if (showSelectionBadge)
                          PositionedDirectional(
                            top: 8.0.s,
                            end: 8.0.s,
                            child: SelectionBadge(
                              isSelected: selectionState.isSelected,
                              selectionOrder: selectionState.order.toString(),
                            ),
                          ),
                        if (asset.type == AssetType.video)
                          PositionedDirectional(
                            bottom: 4.0.s,
                            end: 4.0.s,
                            child: DurationBadge(
                              duration: asset.duration,
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return const ShimmerLoadingCell();
                }
              },
              errorBuilder: (_, __, ___) => const ShimmerLoadingCell(),
            ),
          );
        },
        orElse: () => const ShimmerLoadingCell(),
      ),
    );
  }

  bool _validateAsset({
    required AssetEntity asset,
    required BuildContext context,
    int? maxVideoDurationInSeconds,
  }) {
    final isVideo = asset.type == AssetType.video;
    if (isVideo) {
      final isVideoDurationValid =
          maxVideoDurationInSeconds == null || asset.duration <= maxVideoDurationInSeconds;

      if (!isVideoDurationValid) {
        unawaited(
          showSimpleBottomSheet<void>(
            context: context,
            child: const UploadLimitReachedModal(
              type: UploadLimitModalType.video,
            ),
          ),
        );
      }

      return isVideoDurationValid;
    }

    return true;
  }
}
