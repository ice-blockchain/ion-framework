// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/mention_inline_widget.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/features/tokenized_communities/extensions/replaceable_entity.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

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
    // Ensure inline sizing follows text metrics.
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
  });

  final String pubkey;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final externalAddress = ref.watch(
      userMetadataProvider(pubkey, network: false)
          .select((value) => value.valueOrNull?.externalAddress),
    );

    // Strip the 'a' prefix for API calls (prefix is only for blockchain operations)
    // externalAddress format: "a0:pubkey:" -> API expects: "0:pubkey:"
    //TODO: move to extension
    final apiAddress = externalAddress?.substring(1);

    final tokenInfo = apiAddress != null ? ref.watch(tokenMarketInfoProvider(apiAddress)) : null;
    final marketCap = tokenInfo?.valueOrNull?.marketData.marketCap;

    return MentionInlineWidget(
      username: username,
      marketCap: marketCap ?? 0,
    );
  }
}
