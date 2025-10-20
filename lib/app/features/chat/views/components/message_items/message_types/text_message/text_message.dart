// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_span_builder/hooks/use_text_span_builder.dart';
import 'package:ion/app/components/text_span_builder/text_span_builder.dart';
import 'package:ion/app/components/url_preview/providers/url_metadata_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/hooks/use_has_reaction.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/components.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';

class TextMessage extends HookConsumerWidget {
  const TextMessage({
    required this.eventMessage,
    this.margin,
    this.onTapReply,
    super.key,
  });

  final VoidCallback? onTapReply;
  final EventMessage eventMessage;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstUrl = useState<String?>(null);

    //TODO: re-enable once isolate issue is resolved
    //useOnInit(() {
    //  sharedChatIsolate.compute(extractFirstUrl, eventMessage.content).then((url) {
    //    if (context.mounted) {
    //      firstUrl.value = url;
    //    }
    //  });
    //});

    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final textStyle = context.theme.appTextThemes.body2.copyWith(
      color: isMe ? context.theme.appColors.onPrimaryAccent : context.theme.appColors.primaryText,
    );

    final metadata =
        firstUrl.value != null ? ref.watch(urlMetadataProvider(firstUrl.value!)) : null;

    final hasReactionsOrMetadata =
        useHasReaction(entity.toEventReference(), ref) || metadata != null;

    final messageItem = useMemoized(
      () => TextItem(
        eventMessage: eventMessage,
        contentDescription: eventMessage.content,
        isStoryReply: entity.data.quotedEvent != null,
      ),
      [eventMessage, entity.data.quotedEvent],
    );

    final repliedEventMessage = ref.watch(repliedMessageListItemProvider(messageItem));

    final repliedMessageItem = getRepliedMessageListItem(
      ref: ref,
      repliedEventMessage: repliedEventMessage.valueOrNull,
    );

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: messageItem,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 12.0.s),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (repliedMessageItem != null)
              ReplyMessage(messageItem, repliedMessageItem, onTapReply),
            _TextMessageContent(
              textStyle: textStyle,
              eventMessage: eventMessage,
              hasReactionsOrMetadata: hasReactionsOrMetadata,
              hasRepliedMessage: repliedMessageItem != null,
              hasUrlInText: firstUrl.value != null,
            ),
            if (metadata != null) UrlPreviewBlock(url: firstUrl.value!, isMe: isMe),
            if (hasReactionsOrMetadata)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: MessageReactions(isMe: isMe, eventMessage: eventMessage)),
                  MessageMetadata(eventMessage: eventMessage, startPadding: 0.0.s),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TextMessageContent extends HookWidget {
  const _TextMessageContent({
    required this.textStyle,
    required this.eventMessage,
    required this.hasReactionsOrMetadata,
    required this.hasRepliedMessage,
    required this.hasUrlInText,
  });

  final TextStyle textStyle;
  final EventMessage eventMessage;
  final bool hasReactionsOrMetadata;
  final bool hasRepliedMessage;
  final bool hasUrlInText;
  @override
  Widget build(BuildContext context) {
    final maxAvailableWidth = MessageItemWrapper.maxWidth - (12.0.s * 2);
    final content = eventMessage.content;

    final metadataRef = useRef(GlobalKey());

    final metadataWidth = useState<double>(0);

    final textScaler = MediaQuery.textScalerOf(context);

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = metadataRef.value.currentContext?.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize && box.size.width > 0) {
            metadataWidth.value = box.size.width;
          }
        });
        return null;
      },
      [eventMessage, textScaler],
    );

    final oneLineTextPainter = TextPainter(
      text: TextSpan(text: content, style: textStyle),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
      textScaler: textScaler,
    )..layout(maxWidth: maxAvailableWidth - metadataWidth.value.s);

    final oneLineMetrics = oneLineTextPainter.computeLineMetrics();
    oneLineTextPainter.dispose();

    final multiline = oneLineMetrics.length > 1 && !oneLineMetrics.every((m) => m.hardBreak);
    if (hasReactionsOrMetadata) {
      return _TextRichContent(
        text: content,
        textStyle: textStyle,
        hasUrlInText: hasUrlInText,
      );
    }
    if (!multiline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _TextRichContent(
            text: content,
            textStyle: textStyle,
            hasUrlInText: hasUrlInText,
          ),
          if (hasRepliedMessage) const Spacer(),
          Offstage(
            offstage: metadataWidth.value.s <= 0,
            child: MessageMetadata(eventMessage: eventMessage, key: metadataRef.value),
          ),
        ],
      );
    } else {
      final multiLineTextPainter = TextPainter(
        text: TextSpan(text: content, style: textStyle),
        textDirection: TextDirection.ltr,
        textWidthBasis: TextWidthBasis.longestLine,
        textScaler: textScaler,
      )..layout(maxWidth: maxAvailableWidth);

      final lineMetrics = multiLineTextPainter.computeLineMetrics();
      multiLineTextPainter.dispose();

      final wouldOverlap = lineMetrics.last.width > (maxAvailableWidth - metadataWidth.value.s);

      return Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          _TextRichContent(
            text: wouldOverlap ? '$content\n' : content,
            textStyle: textStyle,
            hasUrlInText: hasUrlInText,
          ),
          Offstage(
            offstage: metadataWidth.value.s <= 0,
            child: MessageMetadata(
              eventMessage: eventMessage,
              key: metadataRef.value,
            ),
          ),
        ],
      );
    }
  }
}

class _TextRichContent extends HookConsumerWidget {
  const _TextRichContent({
    required this.textStyle,
    required this.text,
    required this.hasUrlInText,
  });

  final TextStyle textStyle;
  final String text;
  final bool hasUrlInText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasUrlInText) {
      return Text.rich(TextSpan(text: text, style: textStyle));
    }
    final textSpan = useTextSpanBuilder(
      context,
      defaultStyle: textStyle,
      matcherStyles: {
        const UrlMatcher(): textStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: textStyle.color,
        ),
      },
    ).build(
      TextParser(matchers: {const UrlMatcher()}).parse(text),
      onTap: (match) => TextSpanBuilder.defaultOnTap(ref, match: match),
    );
    return Text.rich(textSpan);
  }
}
