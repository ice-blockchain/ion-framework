// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/providers/message_status_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class MessageMetadata extends HookConsumerWidget {
  const MessageMetadata({
    required this.eventMessage,
    this.displayTime = true,
    this.displayEdited = true,
    super.key,
    this.startPadding,
    this.deliveryStatusIconSize,
  });

  final bool displayTime;
  final bool displayEdited;
  final double? startPadding;
  final double? deliveryStatusIconSize;
  final EventMessage eventMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventReference =
        ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage).toEventReference();

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      return const SizedBox.shrink();
    }
    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final deliveryStatus = ref.watch(messageStatusProvider(eventReference));

    final entityData = ReplaceablePrivateDirectMessageData.fromEventMessage(eventMessage);

    return Padding(
      padding: EdgeInsetsDirectional.only(start: startPadding ?? 8.0.s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (displayEdited &&
              (entityData.messageType == MessageType.text ||
                  entityData.messageType == MessageType.emoji) &&
              (eventMessage.createdAt.toDateTime
                      .difference(entityData.publishedAt.value.toDateTime)
                      .inSeconds >
                  2))
            Text(
              context.i18n.common_message_edited,
              style: context.theme.appTextThemes.caption5.copyWith(
                color: isMe
                    ? context.theme.appColors.strokeElements
                    : context.theme.appColors.quaternaryText,
              ),
            ),
          SizedBox(width: 2.0.s),
          if (displayTime)
            Text(
              toTimeDisplayValue(entityData.publishedAt.value.toDateTime.millisecondsSinceEpoch),
              style: context.theme.appTextThemes.caption5.copyWith(
                color: isMe
                    ? context.theme.appColors.strokeElements
                    : context.theme.appColors.quaternaryText,
              ),
            ),
          if (isMe)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 2.0.s),
              child: (deliveryStatus.valueOrNull ?? MessageDeliveryStatus.created) ==
                      MessageDeliveryStatus.created
                  ? SizedBox(width: 12.0.s)
                  : statusIcon(
                      context,
                      deliveryStatus.valueOrNull ?? MessageDeliveryStatus.created,
                      deliveryStatusIconSize,
                    ),
            ),
        ],
      ),
    );
  }

  Widget statusIcon(BuildContext context, MessageDeliveryStatus deliveryStatus, double? size) {
    return switch (deliveryStatus) {
      MessageDeliveryStatus.deleted => const SizedBox.shrink(),
      MessageDeliveryStatus.created => const SizedBox.shrink(),
      MessageDeliveryStatus.failed => const SizedBox.shrink(),
      MessageDeliveryStatus.sent => Assets.svg.iconMessageSent.icon(
          color: context.theme.appColors.strokeElements,
          size: size ?? 12.0.s,
        ),
      MessageDeliveryStatus.received => Assets.svg.iconMessageDelivered.icon(
          color: context.theme.appColors.strokeElements,
          size: size ?? 12.0.s,
        ),
      MessageDeliveryStatus.read => Assets.svg.iconMessageDelivered.icon(
          color: context.theme.appColors.success,
          size: size ?? 12.0.s,
        ),
    };
  }
}
