// SPDX-License-Identifier: ice License 1.0

part of 'poll_message.dart';

class PollResultMessage extends StatelessWidget {
  const PollResultMessage({
    required this.isMe,
    required this.createdAt,
    required this.eventMessage,
    super.key,
    this.reactions,
  });

  final bool isMe;
  final DateTime createdAt;
  final EventMessage eventMessage;
  final List<MessageReaction>? reactions;

  @override
  Widget build(BuildContext context) {
    return MessageItemWrapper(
      // TODO: Add corresponding message item
      messageItem: TextItem(
        eventMessage: eventMessage,
        contentDescription: eventMessage.content,
      ),
      contentPadding: EdgeInsets.all(
        12.0.s,
      ),
      isMe: isMe,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _PollItemList(isMe: isMe),
          SizedBox(height: 10.0.s),
          Text(
            'Votes: 2  •  Left: 1 day 2 hours',
            style: context.theme.appTextThemes.caption2.copyWith(
              color: isMe
                  ? context.theme.appColors.strokeElements
                  : context.theme.appColors.quaternaryText,
            ),
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

class _PollItemList extends StatelessWidget {
  const _PollItemList({
    required this.isMe,
  });

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final option = mockPoll.options[index];

        return _PollResultItem(isMe: isMe, option: option);
      },
      separatorBuilder: (context, index) => SizedBox(height: 10.0.s),
      itemCount: mockPoll.options.length,
    );
  }
}

class _PollResultItem extends HookWidget {
  const _PollResultItem({
    required this.isMe,
    required this.option,
  });

  final bool isMe;
  final PollItem option;

  @override
  Widget build(BuildContext context) {
    final percentage = useMemoized(
      () {
        return option.votes /
            mockPoll.options.map((e) => e.votes).reduce((value, element) => value + element);
      },
      [option.votes, ...mockPoll.options.map((e) => e.votes)],
    );

    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 28.0.s,
            borderRadius: BorderRadius.circular(12.0.s),
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              isMe ? context.theme.appColors.darkBlue : context.theme.appColors.onTertiaryFill,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: 12.0.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                option.option,
                style: context.theme.appTextThemes.caption2.copyWith(
                  color: isMe
                      ? context.theme.appColors.onPrimaryAccent
                      : context.theme.appColors.primaryText,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: context.theme.appTextThemes.caption2.copyWith(
                  color: isMe
                      ? context.theme.appColors.onPrimaryAccent
                      : context.theme.appColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
