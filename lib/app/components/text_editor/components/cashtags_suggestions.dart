// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/coins_group_token_market_cap_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/market_cap_badge.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';

class CashtagsSuggestions extends StatelessWidget {
  const CashtagsSuggestions({
    required this.suggestions,
    required this.onSuggestionSelected,
    super.key,
  });

  final List<CoinsGroup> suggestions;
  final ValueChanged<CoinsGroup> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const HorizontalSeparator(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 5.0.s),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return _CashtagSuggestionTile(
                  suggestion: suggestion,
                  onTap: () => onSuggestionSelected(suggestion),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CashtagSuggestionTile extends ConsumerWidget {
  const _CashtagSuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  final CoinsGroup suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketCap = ref.watch(coinsGroupTokenMarketCapProvider(suggestion));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        height: 30.0.s,
        padding: EdgeInsetsDirectional.only(end: 8.0.s),
        child: Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: context.theme.appTextThemes.caption.copyWith(
                  color: context.theme.appColors.primaryText,
                ),
                child: Text(suggestion.symbolGroup),
              ),
            ),
            if (marketCap != null) MarketCapBadge(marketCap: marketCap),
          ],
        ),
      ),
    );
  }
}
