// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/providers/message_status_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reaction_dialog/message_reaction_dialog.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';

import 'package:ion/generated/assets.gen.dart';

class SharedStoryWrapper extends HookConsumerWidget {
  const SharedStoryWrapper({
    required this.messageItem,
    required this.sharedEntity,
    required this.child,
    super.key,
  });

  final Widget child;
  final ChatMessageInfoItem messageItem;
  final ReplaceablePrivateDirectMessageEntity sharedEntity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageItemKey = useMemoized(GlobalKey.new);

    final isMe = ref.watch(isCurrentUserSelectorProvider(sharedEntity.masterPubkey));

    final sharedPostMessageStatus = ref.watch(
          sharedPostMessageStatusProvider(sharedEntity).select((value) {
            final status = value.valueOrNull;

            if (status != null) {
              ListCachedObjects.updateObject<MessageStatusWithKey>(
                context,
                (key: sharedEntity.toEventReference().toString(), status: status),
              );
            }
            return status;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<MessageStatusWithKey>(
          context,
          sharedEntity.toEventReference().toString(),
        )?.status ??
        MessageDeliveryStatus.sent;

    final showReactDialog = useCallback(
      () async {
        await showDialog<String>(
          context: context,
          barrierColor: Colors.transparent,
          useSafeArea: false,
          builder: (context) => MessageReactionDialog(
            isMe: isMe,
            messageItem: messageItem,
            isSharedStory: true,
            messageStatus: sharedPostMessageStatus,
            renderObject: messageItemKey.currentContext!.findRenderObject()!,
          ),
        );
      },
      [messageItemKey, isMe, sharedEntity, sharedPostMessageStatus],
    );

    return sharedPostMessageStatus == MessageDeliveryStatus.deleted
        ? const SizedBox.shrink()
        : ScreenSideOffset.small(
            child: Align(
              alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: GestureDetector(
                onLongPress: showReactDialog,
                child: RepaintBoundary(
                  key: messageItemKey,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      child,
                      if (sharedPostMessageStatus == MessageDeliveryStatus.failed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 6.0.s),
                            Assets.svg.iconMessageFailed.icon(
                              color: context.theme.appColors.attentionRed,
                              size: 16.0.s,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
