// SPDX-License-Identifier: ice License 1.0

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chat_overlay/components/encrypted_direct_chat_overlay_context_menu.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chat_overlay/components/encrypted_group_chat_overlay_context_menu.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class RecentChatOverlay extends HookConsumerWidget {
  const RecentChatOverlay({
    required this.renderObject,
    required this.conversation,
    super.key,
  });

  /// The key of the message item to capture the image from widget tree
  final RenderObject renderObject;
  final ConversationListItem conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capturedImage = useFuture(
      useMemoized(
        () => ref.read(mediaServiceProvider).captureWidgetAsImage(renderObject),
        [renderObject],
      ),
    );

    if (!capturedImage.hasData) {
      return const SizedBox.shrink();
    }

    final isDirectEncrypted = conversation.type == ConversationType.directEncrypted;

    final (:imageBytes, :position, :size) = capturedImage.data!;

    /// The available height for the message content in the dialog
    final availableHeight = MediaQuery.sizeOf(context).height -
        (isDirectEncrypted
            ? EncryptedDirectChatOverlayContextMenu.height
            : EncryptedGroupChatOverlayContextMenu.height) -
        MediaQuery.paddingOf(context).bottom -
        MediaQuery.paddingOf(context).top;

    /// Determine the height of the message content in the dialog to fit the available height
    final contentHeight = min(size.height, availableHeight);

    /// Whether the message content is larger than the available height
    final isHugeComponent = size.height > availableHeight;

    /// The y-coordinate of the bottom of the message content
    final bottomdY = position.dy + size.height;

    /// The overflow size of the message content in the dialog
    final overflowBottomSize = MediaQuery.sizeOf(context).height -
        // bottomdY -
        (position.dy > 0 ? (isHugeComponent ? 0 : bottomdY) : bottomdY) -
        (isDirectEncrypted
            ? EncryptedDirectChatOverlayContextMenu.height
            : EncryptedGroupChatOverlayContextMenu.height) -
        MediaQuery.paddingOf(context).bottom;

    /// The y-coordinate of the top of the message content in the dialog
    final topY = isHugeComponent
        ? null
        : overflowBottomSize < 0
            ? null
            : position.dy;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              color: context.theme.appColors.primaryText.withValues(alpha: 0.5),
            ),
          ),
        ),
        PositionedDirectional(
          end: ScreenSideOffset.defaultSmallMargin,
          top: topY,
          bottom: MediaQuery.paddingOf(context).bottom,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0.s),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0.s),
                  ),
                  child: Image.memory(
                    imageBytes,
                    height: contentHeight,
                    width: size.width - 24.0.s,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                IntrinsicWidth(
                  child: isDirectEncrypted
                      ? EncryptedDirectChatOverlayContextMenu(conversation: conversation)
                      : EncryptedGroupChatOverlayContextMenu(conversation: conversation),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
