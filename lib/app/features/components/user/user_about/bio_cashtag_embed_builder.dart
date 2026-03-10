// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/models/cashtag_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/text_editor_cashtag_embed_builder.dart';
import 'package:ion/app/features/components/user/user_about/bio_embed_market_cap.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

// Compact cashtag layout for bio. Posts/articles use TextEditorCashtagEmbedBuilder.
class BioCashtagEmbedBuilder extends EmbedBuilder {
  const BioCashtagEmbedBuilder();

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

    final map = Map<String, dynamic>.from(raw);
    final data = (map.containsKey(cashtagEmbedKey) && map.length == 1)
        ? Map<String, dynamic>.from(map[cashtagEmbedKey] as Map)
        : map;

    final embedData = CashtagEmbedData.fromJson(data);

    return _BioCashtagWidget(
      ticker: embedData.displayTicker,
      externalAddress: embedData.externalAddress,
    );
  }
}

class _BioCashtagWidget extends ConsumerWidget {
  const _BioCashtagWidget({
    required this.ticker,
    required this.externalAddress,
  });

  final String ticker;
  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketCap = ref.watch(
      tokenMarketInfoProvider(externalAddress).select(
        (state) => state.valueOrNull?.marketData.marketCap,
      ),
    );

    return BioEmbedMarketCap(
      label: '\$$ticker',
      marketCap: marketCap,
      onTap: () => TokenizedCommunityRoute(externalAddress: externalAddress).push<void>(context),
    );
  }
}
