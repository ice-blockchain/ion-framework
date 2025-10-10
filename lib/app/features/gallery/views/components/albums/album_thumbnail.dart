// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/gallery/providers/albums_provider.r.dart';
import 'package:ion/app/features/gallery/views/components/shimmer_loading_cell.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class AlbumThumbnail extends ConsumerWidget {
  const AlbumThumbnail({required this.albumId, required this.isNeedFilterVideoByFormat, super.key});

  final String albumId;
  final bool isNeedFilterVideoByFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      albumPreviewProvider(
        albumId,
        isNeedFilterVideoByFormat: isNeedFilterVideoByFormat,
      ),
    );

    return previewAsync.maybeWhen(
      data: (asset) {
        if (asset == null) {
          return const _AlbumShimmerPlaceholder();
        }

        return SizedBox.square(
          dimension: 50.0.s,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0.s),
            child: Image(
              image: AssetEntityImageProvider(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(300),
              ),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
      orElse: () => const _AlbumShimmerPlaceholder(),
    );
  }
}

class _AlbumShimmerPlaceholder extends StatelessWidget {
  const _AlbumShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0.s),
      child: ShimmerLoadingCell(dimension: 50.0.s),
    );
  }
}
