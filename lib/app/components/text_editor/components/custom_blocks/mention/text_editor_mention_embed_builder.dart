// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/common/quill_embed_text_scale_fix.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/mention_embed_utils.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/mention_inline_widget.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/services/mention_insertion_service.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';

export 'package:ion/app/components/text_editor/components/custom_blocks/mention/mention_embed_utils.dart'
    show mentionEmbedKey, mentionPrefix;

class TextEditorMentionEmbedBuilder extends EmbedBuilder {
  const TextEditorMentionEmbedBuilder({this.showClose = true});

  final bool showClose;

  @override
  String get key => mentionEmbedKey;

  @override
  String toPlainText(Embed node) {
    final mentionData = parseMentionEmbedData(node.value.data);
    if (mentionData != null) {
      return '$mentionPrefix${mentionData.username}';
    }
    return '';
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: widget,
    );
  }

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final mentionData = parseMentionEmbedData(embedContext.node.value.data);

    if (mentionData == null) {
      return const SizedBox.shrink();
    }

    return _MentionInlineWidgetWithMarketCap(
      pubkey: mentionData.pubkey,
      username: mentionData.username,
      controller: embedContext.controller,
      embedNode: embedContext.node,
      showClose: showClose,
    );
  }
}

// Wrapper widget that fetches market cap data and renders MentionInlineWidget.
class _MentionInlineWidgetWithMarketCap extends ConsumerWidget {
  const _MentionInlineWidgetWithMarketCap({
    required this.pubkey,
    required this.username,
    required this.controller,
    required this.embedNode,
    required this.showClose,
  });

  final String pubkey;
  final String username;
  final QuillController controller;
  final Embed embedNode;
  final bool showClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketCap = ref.watch(userTokenMarketCapProvider(pubkey));
    return QuillEmbedTextScaler(
      child: MentionInlineWidget(
        username: username,
        marketCap: marketCap ?? 0,
        onClose: showClose
            ? () {
                MentionInsertionService.removeMentionEmbed(controller, embedNode);
              }
            : null,
        onTap: showClose ? null : () => navigateToMentionProfile(context, ref, pubkey),
      ),
    );
  }
}
