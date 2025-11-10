// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/group_media_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/mute_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/url.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupMediaTab extends HookConsumerWidget {
  const GroupMediaTab({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  static const _horizontalPadding = 20.0;
  static const _topPadding = 18.0;
  static const _itemSpacing = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync =
        ref.watch<AsyncValue<List<GroupMediaItem>>>(groupMediaProvider(conversationId));

    return mediaAsync.when(
      data: (List<GroupMediaItem> mediaItems) {
        if (mediaItems.isEmpty) {
          return Center(
            child: Text(
              context.i18n.common_media,
              style: context.theme.appTextThemes.body,
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsetsDirectional.only(
            start: _horizontalPadding.s,
            end: _horizontalPadding.s,
            top: _topPadding.s,
          ),
          itemCount: mediaItems.length,
          separatorBuilder: (context, index) => SizedBox(height: _itemSpacing.s),
          itemBuilder: (context, int index) {
            final mediaItem = mediaItems[index];
            return _GroupMediaCell(
              mediaItem: mediaItem,
              onTap: () {
                // Find all media items from the same event reference
                final sameEventMedia = mediaItems
                    .where((GroupMediaItem item) => item.eventReference == mediaItem.eventReference)
                    .toList();
                final mediaIndex = sameEventMedia.indexOf(mediaItem);

                ChatMediaRoute(
                  eventReference: mediaItem.eventReference.encode(),
                  initialIndex: mediaIndex,
                ).push<void>(context);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
        child: Text(
          context.i18n.common_error,
          style: context.theme.appTextThemes.body,
        ),
      ),
    );
  }
}

class _GroupMediaCell extends HookConsumerWidget {
  const _GroupMediaCell({
    required this.mediaItem,
    required this.onTap,
  });

  static const _cornerRadius = 16.0;

  final GroupMediaItem mediaItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = mediaItem.media;
    final isVideo = media.mediaTypeEncrypted == MediaType.video;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_GroupMediaCell._cornerRadius.s),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MediaThumbnail(
                media: media,
                eventReference: mediaItem.eventReference,
              ),
              if (isVideo && media.duration != null)
                PositionedDirectional(
                  bottom: 12.0.s,
                  start: 12.0.s,
                  child: Container(
                    padding: EdgeInsetsDirectional.only(
                      start: 4.0.s,
                      end: 4.0.s,
                      bottom: 1.0.s,
                    ),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: context.theme.appColors.backgroundSheet.withValues(alpha: 0xB2 / 0xFF),
                      borderRadius: BorderRadius.circular(6.0.s),
                    ),
                    child: Text(
                      formatDuration(Duration(seconds: media.duration!)),
                      style: context.theme.appTextThemes.caption.copyWith(
                        color: context.theme.appColors.secondaryBackground,
                      ),
                    ),
                  ),
                ),
              if (isVideo)
                PositionedDirectional(
                  bottom: 12.0.s,
                  end: 12.0.s,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isMuted = ref.watch(globalMuteNotifierProvider);
                      return GestureDetector(
                        onTap: () async {
                          await HapticFeedback.lightImpact();
                          if (context.mounted) {
                            await ref.read(globalMuteNotifierProvider.notifier).toggle();
                          }
                        },
                        child: SizedBox(
                          width: 28.0.s,
                          height: 28.0.s,
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.theme.appColors.backgroundSheet.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                            child: Center(
                              child: (isMuted
                                      ? Assets.svg.iconChannelMute
                                      : Assets.svg.iconChannelUnmute)
                                  .icon(
                                size: 16.0.s,
                                color: context.theme.appColors.onPrimaryAccent,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaThumbnail extends HookConsumerWidget {
  const _MediaThumbnail({
    required this.media,
    required this.eventReference,
  });

  final MediaAttachment media;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailUrl = media.thumb ?? media.url;
    final isRemoteUrl = isNetworkUrl(thumbnailUrl);

    if (!isRemoteUrl) {
      return Image.file(
        File(thumbnailUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    final fileFuture = useFuture<String?>(
      useMemoized(
        () async {
          final cachedData =
              await ref.read(ionConnectFileCacheServiceProvider).getFileFromCache(thumbnailUrl);

          if (cachedData != null) {
            return cachedData.file.path;
          }

          // Try to load the media using the entity
          try {
            final eventMessage =
                await ref.read(eventMessageDaoProvider).getByReference(eventReference);
            final entity = EncryptedGroupMessageEntity.fromEventMessage(eventMessage);

            // Get thumbnail from media attachments
            final mediaAttachmentToLoad = entity.data.media.values.firstWhere(
              (e) => e.url == media.thumb,
              orElse: () => media,
            );

            final file = await ref.read(mediaEncryptionServiceProvider).getEncryptedMedia(
                  mediaAttachmentToLoad,
                  authorPubkey: entity.masterPubkey,
                );

            return file.path;
          } catch (_) {
            return null;
          }
        },
        [thumbnailUrl, eventReference],
      ),
    );

    if (!fileFuture.hasData) {
      return const SizedBox.shrink();
    }

    final path = fileFuture.data;
    if (path == null) {
      return const SizedBox.shrink();
    }

    if (fileFuture.hasError) {
      return const SizedBox.shrink();
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
