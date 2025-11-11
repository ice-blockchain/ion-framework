// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_message_media_path_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/group_media_provider.r.dart'
    show GroupMediaItem, groupFilesItemsProvider;
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:ion/app/utils/filesize.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupFilesTab extends ConsumerWidget {
  const GroupFilesTab({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch<AsyncValue<List<GroupMediaItem>>>(
      groupFilesItemsProvider(conversationId),
    );

    return filesAsync.when(
      data: (List<GroupMediaItem> files) {
        if (files.isEmpty) {
          return Center(
            child: Text(
              context.i18n.common_document,
              style: context.theme.appTextThemes.body,
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsetsDirectional.only(
            start: 16.0.s,
            end: 16.0.s,
            top: 18.0.s,
          ),
          itemCount: files.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.0.s),
          itemBuilder: (context, int index) {
            final fileItem = files[index];
            return _GroupFileCell(
              fileName: fileItem.media.alt ?? 'File',
              eventReference: fileItem.eventReference,
              publishedAt: fileItem.publishedAt,
              media: fileItem.media,
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stack) => Center(
        child: Text(
          context.i18n.common_error,
          style: context.theme.appTextThemes.body,
        ),
      ),
    );
  }
}

class _GroupFileCell extends HookConsumerWidget {
  const _GroupFileCell({
    required this.fileName,
    required this.eventReference,
    required this.publishedAt,
    required this.media,
  });

  final String fileName;
  final EventReference eventReference;
  final int publishedAt;
  final MediaAttachment media;

  String _formatDateAndTime(int timestamp) {
    final date = timestamp.toDateTime;
    final dateStr = DateFormat('d MMM yyyy').format(date);
    final timeStr = DateFormat('HH:mm').format(date);
    return '$dateStr • $timeStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventMessageFuture = useFuture(
      useMemoized(
        () => ref.read(eventMessageDaoProvider).getByReference(eventReference),
        [eventReference],
      ),
    );

    final entity = useMemoized(
      () {
        if (eventMessageFuture.hasData && eventMessageFuture.data != null) {
          return EncryptedGroupMessageEntity.fromEventMessage(eventMessageFuture.data!);
        }
        return null;
      },
      [eventMessageFuture.hasData, eventMessageFuture.data],
    );

    final localMediaPath = entity != null
        ? ref.watch(
            chatMessageMediaPathProvider(
              entity: entity,
              loadThumbnail: false,
              mediaAttachment: media,
            ).select((value) => value.valueOrNull),
          )
        : null;

    final fileSizeStr = localMediaPath != null ? formattedFileSize(localMediaPath) ?? '0kb' : '0kb';
    final dateTimeStr = _formatDateAndTime(publishedAt);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (localMediaPath != null) {
          shareFile(localMediaPath, name: fileName);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.0.s),
        decoration: BoxDecoration(
          color: context.theme.appColors.tertiaryBackground,
          borderRadius: BorderRadius.circular(16.0.s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.0.s,
                  height: 36.0.s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0.s),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0.s),
                    child: ColoredBox(
                      color: context.theme.appColors.tertiaryBackground,
                      child: Center(
                        child: Assets.svg.iconFeedAddfile.icon(
                          size: 20.0.s,
                          color: context.theme.appColors.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.0.s),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: context.theme.appTextThemes.subtitle3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$fileSizeStr • $dateTimeStr',
                      style: context.theme.appTextThemes.caption.copyWith(
                        color: context.theme.appColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
