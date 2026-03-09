// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/mention_embed_utils.dart';
import 'package:ion/app/features/components/user/user_about/bio_embed_market_cap.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';

// Compact mention layout for bio. Posts/articles use TextEditorMentionEmbedBuilder.
class BioMentionEmbedBuilder extends EmbedBuilder {
  const BioMentionEmbedBuilder();

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

    return _BioMentionWidget(
      pubkey: mentionData.pubkey,
      username: mentionData.username,
    );
  }
}

class _BioMentionWidget extends ConsumerWidget {
  const _BioMentionWidget({
    required this.pubkey,
    required this.username,
  });

  final String pubkey;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketCap = ref.watch(userTokenMarketCapProvider(pubkey));

    return BioEmbedMarketCap(
      label: '$mentionPrefix$username',
      marketCap: marketCap,
      onTap: () => navigateToMentionProfile(context, ref, pubkey),
    );
  }
}
