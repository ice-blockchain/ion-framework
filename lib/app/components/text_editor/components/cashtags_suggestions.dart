// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/market_cap_badge.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

class CashtagsSuggestions extends StatelessWidget {
  const CashtagsSuggestions({
    required this.suggestions,
    required this.onSuggestionSelected,
    super.key,
  });

  final List<CoinData> suggestions;
  final ValueChanged<CoinData> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final tickerCounts = <String, int>{};
    for (final s in suggestions) {
      final ticker = s.abbreviation.toUpperCase();
      tickerCounts[ticker] = (tickerCounts[ticker] ?? 0) + 1;
    }

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
                final ticker = suggestion.abbreviation.toUpperCase();
                return _CashtagSuggestionTile(
                  suggestion: suggestion,
                  showName: (tickerCounts[ticker] ?? 0) > 1,
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
    required this.showName,
    required this.onTap,
  });

  final CoinData suggestion;
  final bool showName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final externalAddress = suggestion.tokenizedCommunityExternalAddress;
    final marketCap = externalAddress != null && externalAddress.isNotEmpty
        ? ref.watch(
            tokenMarketInfoProvider(externalAddress).select(
              (state) => state.valueOrNull?.marketData.marketCap,
            ),
          )
        : null;

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
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: suggestion.abbreviation.toUpperCase(),
                      style: context.theme.appTextThemes.caption.copyWith(
                        color: context.theme.appColors.primaryText,
                      ),
                    ),
                    if (showName)
                      TextSpan(
                        text: ' (${suggestion.name})',
                        style: context.theme.appTextThemes.caption.copyWith(
                          color: context.theme.appColors.quaternaryText,
                        ),
                      ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (marketCap != null) MarketCapBadge(marketCap: marketCap),
          ],
        ),
      ),
    );
  }
}
