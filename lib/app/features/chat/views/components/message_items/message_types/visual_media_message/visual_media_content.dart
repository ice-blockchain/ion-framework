// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:blurhash_ffi/blurhashffi_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_medias_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_message_load_media_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_chat_media_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/components/entities_list/list_cached_entities.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class VisualMediaContent extends HookConsumerWidget {
  const VisualMediaContent({
    required this.messageMediaTableData,
    required this.eventMessage,
    required this.height,
    this.isReply = false,
    super.key,
  });

  final MessageMediaTableData messageMediaTableData;
  final EventMessage eventMessage;
  final double height;
  final bool isReply;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedPath = ListCachedObjects.maybeObjectOf<PathWithKey>(
      context,
      messageMediaTableData.remoteUrl,
    )?.filePath;

    final localFile = useState<File?>(cachedPath != null ? File(cachedPath) : null);

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );
    final mediaAttachment = entity.data.media[messageMediaTableData.remoteUrl];

    useEffect(
      () {
        ref
            .read(
          chatMessageLoadMediaProvider(
            entity: entity,
            mediaAttachment: mediaAttachment,
            cacheKey: messageMediaTableData.cacheKey,
          ),
        )
            .then((file) {
          if (context.mounted) {
            if (file == null || messageMediaTableData.remoteUrl == null) return;
            ListCachedObjects.updateObject<PathWithKey>(
              context,
              (key: messageMediaTableData.remoteUrl!, filePath: file.path),
            );
            localFile.value = file;
          }
        });
        return null;
      },
      [mediaAttachment?.thumb, messageMediaTableData.cacheKey],
    );

    if (localFile.value == null && mediaAttachment?.blurhash == null) {
      return const SizedBox.shrink();
    }

    final isVideo =
        MediaType.fromMimeType(mediaAttachment?.originalMimeType ?? '') == MediaType.video;

    return GestureDetector(
      onTap: () async {
        final messageMedias =
            await ref.read(chatMediasProvider(eventReference: entity.toEventReference()).future);

        if (context.mounted) {
          await ChatMediaRoute(
            eventReference: entity.toEventReference().encode(),
            initialIndex: messageMedias.indexOf(messageMediaTableData),
          ).push<void>(context);
        }
      },
      child: Stack(
        key: Key(messageMediaTableData.id.toString()),
        alignment: Alignment.center,
        children: [
          if (mediaAttachment?.blurhash != null && localFile.value == null)
            ClipRRect(
              borderRadius: BorderRadius.circular(height <= 30.0.s ? 2.0.s : 5.0.s),
              child: SizedBox(
                height: height,
                child: BlurhashFfi(
                  hash: mediaAttachment!.blurhash!,
                ),
              ),
            ),
          if (localFile.value != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(height <= 30.0.s ? 2.0.s : 5.0.s),
              child: Image.file(
                localFile.value!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
              ),
            ),
          if (isVideo && !isReply)
            Align(
              child: Container(
                padding: EdgeInsets.all(6.0.s),
                decoration: BoxDecoration(
                  color: context.theme.appColors.backgroundSheet.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12.0.s),
                ),
                child: Assets.svg.iconVideoPlay.icon(
                  size: 16.0.s,
                ),
              ),
            ),
          if (isVideo && mediaAttachment?.duration != null && !isReply)
            _VideoDurationLabel(duration: mediaAttachment!.duration!),
          if (messageMediaTableData.status == MessageMediaStatus.processing)
            CancelButton(
              messageMediaId: messageMediaTableData.id,
            ),
        ],
      ),
    );
  }
}

class CancelButton extends ConsumerWidget {
  const CancelButton({
    required this.messageMediaId,
    super.key,
  });

  final int messageMediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(sendChatMediaProvider(messageMediaId).notifier).cancel();
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.appColors.backgroundSheet.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.all(2.0.s),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Assets.svg.iconSheetClose.icon(
              size: 16.0.s,
              color: context.theme.appColors.onPrimaryAccent,
            ),
            SizedBox(
              width: 26.0.s,
              height: 26.0.s,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: context.theme.appColors.onPrimaryAccent,
                strokeCap: StrokeCap.round,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoDurationLabel extends StatelessWidget {
  const _VideoDurationLabel({
    required this.duration,
  });

  final int duration;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      bottom: 5.0.s,
      start: 5.0.s,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 4.0.s),
        decoration: BoxDecoration(
          color: context.theme.appColors.backgroundSheet.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6.0.s),
        ),
        child: Text(
          formatDuration(Duration(seconds: duration)),
          style: context.theme.appTextThemes.caption.copyWith(
            color: context.theme.appColors.secondaryBackground,
          ),
        ),
      ),
    );
  }
}
