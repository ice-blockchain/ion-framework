// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
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
import 'package:ion_ads/ion_ads.dart';

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
    // Parse the message once and cache the result
    // This avoids running the UrlMatcher regex multiple times
    final parsedMatches = useMemoized(
      () => TextParser(matchers: {const UrlMatcher()}).parse(
        eventMessage.content,
        onlyMatches: true,
      ),
      [eventMessage.content],
    );

    // Extract first URL from parsed matches (no regex needed!)
    final firstUrl = useMemoized(
      () {
        try {
          return parsedMatches.firstWhere((match) => match.matcher is UrlMatcher).text;
        } catch (_) {
          return '';
        }
      },
      [parsedMatches],
    );

    final hasUrlInText = firstUrl.isNotEmpty;

    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final isAd = eventMessage.id.startsWith('ad_id_') && !isMe;

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final textStyle = context.theme.appTextThemes.body2.copyWith(
      color: isMe ? context.theme.appColors.onPrimaryAccent : context.theme.appColors.primaryText,
    );

    final metadata = hasUrlInText ? ref.watch(urlMetadataProvider(firstUrl)) : null;

    final hasReactionsOrMetadata =
        useHasReaction(entity.toEventReference(), ref) || metadata != null;

    final metadataRef = useMemoized(GlobalKey.new);
    final metadataWidth = useState<double>(0);

    final textScaler = MediaQuery.textScalerOf(context);

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = metadataRef.currentContext?.findRenderObject() as RenderBox?;

          if (box != null && box.hasSize && box.size.width > 0) {
            metadataWidth.value = box.size.width;
          }
        });
        return null;
      },
      [eventMessage, textScaler],
    );

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
        child: !isAd
            ? Column(
                crossAxisAlignment:
                    repliedMessageItem != null ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (repliedMessageItem != null)
                    ReplyMessage(messageItem, repliedMessageItem, onTapReply),
                  _TextMessageContent(
                    textStyle: textStyle,
                    eventMessage: eventMessage,
                    hasReactionsOrMetadata: hasReactionsOrMetadata,
                    hasRepliedMessage: repliedMessageItem != null,
                    hasUrlInText: hasUrlInText,
                    metadataWidth: metadataWidth.value,
                    metadataRef: metadataRef,
                  ),
                  if (metadata != null) UrlPreviewBlock(url: firstUrl, isMe: isMe),
                  if (hasReactionsOrMetadata)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: MessageReactions(isMe: isMe, eventMessage: eventMessage)),
                        MessageMetadata(
                          eventMessage: eventMessage,
                          startPadding: 0.0.s,
                          key: metadataRef,
                        ),
                      ],
                    ),
                ],
              )
            : _AdItem(message: eventMessage),
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
    required this.metadataWidth,
    required this.metadataRef,
  });

  final TextStyle textStyle;
  final EventMessage eventMessage;
  final bool hasReactionsOrMetadata;
  final bool hasRepliedMessage;
  final bool hasUrlInText;
  final double metadataWidth;
  final GlobalKey metadataRef;
  @override
  Widget build(BuildContext context) {
    final maxAvailableWidth = MessageItemWrapper.maxWidth - (12.0.s * 2);
    final content = eventMessage.content;

    final textScaler = MediaQuery.textScalerOf(context);

    final oneLineTextPainter = TextPainter(
      text: TextSpan(text: content, style: textStyle),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
      textScaler: textScaler,
    )..layout(maxWidth: maxAvailableWidth - metadataWidth.s);

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
            offstage: metadataWidth.s <= 0,
            child: MessageMetadata(eventMessage: eventMessage, key: metadataRef),
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

      final wouldOverlap = lineMetrics.last.width > (maxAvailableWidth - metadataWidth.s);

      return Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          _TextRichContent(
            text: wouldOverlap ? '$content\n' : content,
            textStyle: textStyle,
            hasUrlInText: hasUrlInText,
          ),
          Offstage(
            offstage: metadataWidth.s <= 0,
            child: MessageMetadata(
              eventMessage: eventMessage,
              key: metadataRef,
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

    // Cache the TextParser instance to avoid recreating it
    final textParser = useMemoized(
      () => TextParser(matchers: {const UrlMatcher()}),
      [],
    );

    // Memoize the parsed result to avoid reparsing on rebuilds
    final parsedText = useMemoized(
      () => textParser.parse(text),
      [text],
    );

    final textSpanBuilder = useTextSpanBuilder(
      context,
      defaultStyle: textStyle,
      matcherStyles: {
        const UrlMatcher(): textStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: textStyle.color,
        ),
      },
    );

    final textSpan = useMemoized(
      () => textSpanBuilder.build(
        parsedText,
        onTap: (match) => TextSpanBuilder.defaultOnTap(ref, match: match),
      ),
      [parsedText, textSpanBuilder],
    );

    return Text.rich(textSpan);
  }
}

class _AdItem extends StatelessWidget {
  const _AdItem({required this.message});

  final EventMessage message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Center(child: IONLoadingIndicatorThemed())),
        SizedBox(
          height: 236,
          width: 246,
          child: AppodealNativeAd(
            options: NativeAdOptions.customOptions(
              nativeAdType: NativeAdType.contentStream,
              adActionButtonConfig: AdActionButtonConfig(
                position: AdActionPosition.bottom,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
