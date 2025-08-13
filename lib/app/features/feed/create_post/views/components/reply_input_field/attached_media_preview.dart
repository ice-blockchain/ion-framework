// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/typedefs/typedefs.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class AttachedMediaPreview extends StatelessWidget {
  const AttachedMediaPreview({
    required this.attachedMediaNotifier,
    required this.attachedMediaLinksNotifier,
    super.key,
  });

  final AttachedMediaNotifier attachedMediaNotifier;
  final AttachedMediaLinksNotifier attachedMediaLinksNotifier;

  @override
  Widget build(BuildContext context) {
    final mediaFiles = attachedMediaNotifier.value;
    final mediaLinks = attachedMediaLinksNotifier.value.values.toList();
    final totalItems = mediaFiles.length + mediaLinks.length;

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50.0.s,
      child: ListView.separated(
        padding: EdgeInsetsDirectional.only(end: 12.0.s),
        scrollDirection: Axis.horizontal,
        itemCount: totalItems,
        separatorBuilder: (_, __) => SizedBox(width: 16.0.s),
        itemBuilder: (context, index) {
          if (index < mediaFiles.length) {
            final media = mediaFiles[index];
            return _PreviewItem.file(
              path: media.path,
              onRemove: () {
                attachedMediaNotifier.value = attachedMediaNotifier.value.toList()..remove(media);
              },
            );
          } else {
            final linkIndex = index - mediaFiles.length;
            final mediaAttachment = mediaLinks[linkIndex];
            return _PreviewItem.url(
              url: mediaAttachment.thumb ?? mediaAttachment.image ?? mediaAttachment.url,
              onRemove: () {
                final updatedMap =
                    Map<String, MediaAttachment>.from(attachedMediaLinksNotifier.value);
                final keyToRemove = attachedMediaLinksNotifier.value.entries
                    .firstWhere((entry) => entry.value == mediaAttachment)
                    .key;
                updatedMap.remove(keyToRemove);
                attachedMediaLinksNotifier.value = updatedMap;
              },
            );
          }
        },
      ),
    );
  }
}

class _PreviewItem extends ConsumerWidget {
  const _PreviewItem({
    required this.path,
    required this.url,
    required this.onRemove,
  });

  const _PreviewItem.file({
    required this.path,
    required this.onRemove,
  }) : url = null;

  const _PreviewItem.url({
    required this.url,
    required this.onRemove,
  }) : path = null;

  final String? path;
  final String? url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    AssetEntity? assetEntity;

    if (currentPubkey == null) {
      return const SizedBox.shrink();
    }

    if (path != null) {
      assetEntity = ref.watch(assetEntityProvider(path!)).valueOrNull;
      if (assetEntity == null) {
        return const SizedBox.shrink();
      }
    }

    return SizedBox.square(
      dimension: 44.0.s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            end: 0.0.s,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0.s),
              child: SizedBox.square(
                dimension: 44.0.s,
                child: assetEntity != null
                    ? Image(
                        image: AssetEntityImageProvider(
                          assetEntity,
                          isOriginal: false,
                        ),
                        fit: BoxFit.cover,
                      )
                    : FeedIONConnectNetworkImage(
                        imageUrl: url!,
                        authorPubkey: currentPubkey,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          PositionedDirectional(
            end: -6.0.s,
            child: GestureDetector(
              onTap: onRemove,
              child: Assets.svg.iconFieldClearmedia.icon(size: 20.0.s),
            ),
          ),
        ],
      ),
    );
  }
}
