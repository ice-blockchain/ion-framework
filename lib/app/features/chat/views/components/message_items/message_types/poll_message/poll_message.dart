// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/message_author.f.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/model/message_reaction.f.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_author/message_author.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/poll_message/mock.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

part 'poll_result_message.dart';

class PollMessage extends HookWidget {
  const PollMessage({
    required this.isMe,
    required this.createdAt,
    required this.eventMessage,
    super.key,
    this.reactions,
    this.author,
    this.isLastMessageFromAuthor = true,
  });

  final bool isMe;
  final int createdAt;
  final MessageAuthor? author;
  final EventMessage eventMessage;
  final bool isLastMessageFromAuthor;
  final List<MessageReaction>? reactions;

  @override
  Widget build(BuildContext context) {
    final selectedId = useState<String?>(null);

    if (selectedId.value != null) {
      return PollResultMessage(
        isMe: isMe,
        reactions: reactions,
        createdAt: createdAt.toDateTime,
        eventMessage: eventMessage,
      );
    }

    return MessageItemWrapper(
      // TODO: Add corresponding message item
      messageItem: TextItem(
        eventMessage: eventMessage,
        contentDescription: eventMessage.content,
      ),
      isLastMessageFromAuthor: isLastMessageFromAuthor,
      contentPadding: EdgeInsets.all(
        12.0.s,
      ),
      isMe: isMe,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MessageAuthorNameWidget(author: author),
          Flexible(
            child: Text(
              mockPoll.question,
              style: context.theme.appTextThemes.body2.copyWith(
                color: isMe
                    ? context.theme.appColors.onPrimaryAccent
                    : context.theme.appColors.primaryText,
              ),
            ),
          ),
          SizedBox(height: 10.0.s),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final option = mockPoll.options[index];
              return Button.compact(
                type: ButtonType.outlined,
                backgroundColor: context.theme.appColors.tertiaryBackground,
                label: Text(
                  option.option,
                  style: context.theme.appTextThemes.caption2
                      .copyWith(color: context.theme.appColors.primaryText),
                ),
                onPressed: () {
                  selectedId.value = option.id;
                },
              );
            },
            separatorBuilder: (context, index) => SizedBox(height: 10.0.s),
            itemCount: mockPoll.options.length,
          ),
          SizedBox(height: 4.0.s),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              //TODO: add metadata
              //MessageReactions(reactions: reactions),
              Spacer(),
              //TODO: add metadata
              // MessageMetaData(isMe: isMe, createdAt: createdAt),
            ],
          ),
        ],
      ),
    );
  }
}
