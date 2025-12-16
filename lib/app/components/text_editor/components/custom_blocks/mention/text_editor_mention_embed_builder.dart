// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/mention_inline_widget.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/services/mention_insertion_service.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';

const String mentionEmbedKey = 'mention';
const String mentionPrefix = '@';

/// Minimal inline mention embed builder for validation/testing.
class TextEditorMentionEmbedBuilder extends EmbedBuilder {
  const TextEditorMentionEmbedBuilder();

  @override
  String get key => mentionEmbedKey;

  @override
  String toPlainText(Embed node) {
    final mentionData = _parseMentionData(node.value.data);
    if (mentionData != null) {
      return '$mentionPrefix${mentionData.username}';
    }
    return '';
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: UnconstrainedBox(
        constrainedAxis: Axis.horizontal,
        child: IntrinsicWidth(child: widget),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final mentionData = _parseMentionData(embedContext.node.value.data);

    if (mentionData == null) {
      return const MentionInlineWidget(
        username: 'demo',
        marketCap: 0,
      );
    }

    return _MentionInlineWidgetWithMarketCap(
      pubkey: mentionData.pubkey,
      username: mentionData.username,
      controller: embedContext.controller,
      embedNode: embedContext.node,
    );
  }

  static MentionEmbedData? _parseMentionData(dynamic data) {
    try {
      if (data is Map) {
        return MentionEmbedData.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (_) {
      // Invalid data
    }
    return null;
  }
}

/// Wrapper widget that fetches market cap data and renders MentionInlineWidget.
class _MentionInlineWidgetWithMarketCap extends ConsumerWidget {
  const _MentionInlineWidgetWithMarketCap({
    required this.pubkey,
    required this.username,
    required this.controller,
    required this.embedNode,
  });

  final String pubkey;
  final String username;
  final QuillController controller;
  final Embed embedNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketCap = ref.watch(userTokenMarketCapProvider(pubkey)).valueOrNull;

    return MentionInlineWidget(
      username: username,
      marketCap: marketCap ?? 0,
      onClose: () {
        MentionInsertionService.removeMentionEmbed(controller, embedNode);
      },
    );
  }
}
