// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/cashtag_inline_widget.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/models/cashtag_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/services/cashtag_insertion_service.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';

const String cashtagEmbedKey = 'cashtag';

class TextEditorCashtagEmbedBuilder extends EmbedBuilder {
  const TextEditorCashtagEmbedBuilder({this.showClose = true});

  final bool showClose;

  @override
  String get key => cashtagEmbedKey;

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
    final raw = embedContext.node.value.data;
    if (raw is! Map) {
      return const SizedBox.shrink();
    }

    // Some deltas wrap the embed value like {cashtag: {...}}; normalize.
    final map = Map<String, dynamic>.from(raw);
    final data = (map.containsKey(cashtagEmbedKey) && map.length == 1)
        ? Map<String, dynamic>.from(map[cashtagEmbedKey] as Map)
        : map;

    final embedData = CashtagEmbedData.fromJson(data);

    return Consumer(
      builder: (context, ref, _) {
        final marketCap = ref.watch(
          tokenMarketInfoProvider(embedData.externalAddress).select(
            (state) => state.valueOrNull?.marketData.marketCap,
          ),
        );

        // If market cap isn't available, fall back to rendering as plain text.
        // (Later phases will handle downgrade processing more globally.)
        if (marketCap == null) {
          return Text(r'$' + embedData.symbolGroup, style: embedContext.textStyle);
        }

        final canClose = showClose && !embedContext.readOnly;
        final mq = MediaQuery.of(context);
        return MediaQuery(
          // To make embedded mention text follow the same scale that the surrounding rich text
          // have to set textScaleFactor cause it is used by embedded quill widgets to text scaling
          // ignore: deprecated_member_use
          data: mq.copyWith(textScaleFactor: 1),
          child: CashtagInlineWidget(
            symbolGroup: embedData.symbolGroup,
            marketCap: marketCap,
            onClose: canClose
                ? () => CashtagInsertionService.removeCashtagEmbed(
                      embedContext.controller,
                      embedContext.node,
                    )
                : null,
          ),
        );
      },
    );
  }
}
