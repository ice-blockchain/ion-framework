// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/providers/delete_media_chat_message_provider.r.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/url.dart';
import 'package:ion/generated/assets.gen.dart';

class ChatMediaContextMenu extends HookConsumerWidget {
  const ChatMediaContextMenu({
    required this.eventMessage,
    required this.activeMedia,
    super.key,
  });

  static double get iconSize => 20.0.s;
  final EventMessage eventMessage;
  final MediaAttachment activeMedia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSave = useCallback(
      () async {
        final isRemoteUrl = isNetworkUrl(activeMedia.url);
        final File file;

        if (isRemoteUrl) {
          final fileInfo =
              await ref.read(ionConnectFileCacheServiceProvider).getFileFromCache(activeMedia.url);
          if (fileInfo == null) {
            return;
          }
          file = fileInfo.file;
        } else {
          file = File(activeMedia.url);
        }

        switch (activeMedia.mediaTypeEncrypted ?? activeMedia.mediaType) {
          case MediaType.image:
            unawaited(ref.read(mediaServiceProvider).saveImageToGallery(file));
          case MediaType.video:
            unawaited(ref.read(mediaServiceProvider).saveVideoToGallery(file));
          case MediaType.audio:
          case MediaType.unknown:
            throw UnimplementedError();
        }
      },
      [activeMedia],
    );

    final onDelete = useCallback(
      () async {
        await ref.read(
          deleteMediaChatMessageProvider(
            eventMessage: eventMessage,
            mediaToDelete: activeMedia,
          ).future,
        );

        if (context.mounted) {
          context.pop();
        }
      },
      [eventMessage, activeMedia],
    );

    return OverlayMenu(
      menuBuilder: (closeMenu) => Column(
        children: [
          OverlayMenuContainer(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0.s),
              child: Column(
                children: [
                  OverlayMenuItem(
                    label: context.i18n.button_save,
                    icon: Assets.svg.iconSecurityDownload
                        .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
                    onPressed: () {
                      closeMenu();
                      onSave();
                    },
                  ),
                  const OverlayMenuItemSeparator(),
                  OverlayMenuItem(
                    label: context.i18n.button_delete,
                    labelColor: context.theme.appColors.attentionRed,
                    icon: Assets.svg.iconBlockDelete
                        .icon(size: iconSize, color: context.theme.appColors.attentionRed),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Assets.svg.iconMorePopup.icon(
        color: context.theme.appColors.onPrimaryAccent,
      ),
    );
  }
}
