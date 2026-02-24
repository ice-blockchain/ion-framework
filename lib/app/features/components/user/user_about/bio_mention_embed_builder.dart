// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/common/quill_embed_text_scale_fix.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/mention_embed_utils.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/generated/assets.gen.dart';

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
    final colors = context.theme.appColors;
    final textStyle = context.theme.appTextThemes.caption2.copyWith(
      height: 1,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return QuillEmbedTextScaler(
      child: GestureDetector(
        onTap: () => navigateToMentionProfile(context, ref, pubkey),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.5.s),
          child: Container(
            padding: EdgeInsetsDirectional.only(
              start: 4.0.s,
              end: 2.0.s,
              top: 2.0.s,
              bottom: 2.0.s,
            ),
            decoration: BoxDecoration(
              color: colors.primaryBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5.0.s),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$mentionPrefix$username',
                  style: textStyle.copyWith(color: colors.lightBlue),
                  strutStyle: const StrutStyle(forceStrutHeight: true),
                  textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
                ),
                if (marketCap != null) ...[
                  SizedBox(width: 2.0.s),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0.s),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        padding: EdgeInsetsDirectional.only(
                          start: 2.0.s,
                          end: 3.0.s,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryBackground.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.0.s),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Assets.svg.iconMemeMarketcap.icon(
                              size: textStyle.fontSize,
                              color: colors.secondaryBackground,
                            ),
                            SizedBox(width: 2.0.s),
                            Text(
                              '\$${MarketDataFormatter.formatCompactNumber(marketCap)}',
                              style: textStyle.copyWith(color: colors.secondaryBackground),
                              strutStyle: const StrutStyle(forceStrutHeight: true),
                              textHeightBehavior:
                                  const TextHeightBehavior(applyHeightToFirstAscent: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
