// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_metadata/message_metadata.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

class VisualMediaMetadata extends HookConsumerWidget {
  const VisualMediaMetadata({
    required this.eventMessage,
    super.key,
  });

  final EventMessage eventMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = useMemoized(
      () => ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey)),
      [eventMessage.masterPubkey],
    );

    final messageContent = eventMessage.content;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (messageContent.isNotEmpty)
                Padding(
                  padding: EdgeInsetsDirectional.only(top: 8.0.s),
                  child: Text(
                    messageContent,
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: isMe
                          ? context.theme.appColors.onPrimaryAccent
                          : context.theme.appColors.primaryText,
                    ),
                  ),
                ),
              MessageReactions(
                isMe: isMe,
                eventMessage: eventMessage,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(top: 8.0.s),
          child: MessageMetadata(eventMessage: eventMessage),
        ),
      ],
    );
  }
}
