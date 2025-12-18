// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_scroll_links_layout.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_content_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_profile_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_twitter_token.dart';
import 'package:ion/app/features/tokenized_communities/hooks/section_visibility_controller.dart';
import 'package:ion/app/features/tokenized_communities/models/trading_stats_formatted.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_trading_stats_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/timeframe_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/trading_stats_extension.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart_stats.dart';
import 'package:ion/app/features/tokenized_communities/views/components/comments_section_compact.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_image.dart';
import 'package:ion/app/features/tokenized_communities/views/components/floating_trade_island.dart';
import 'package:ion/app/features/tokenized_communities/views/components/your_position_card.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/top_holders/top_holders.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/latest_trades/components/latest_trades_card.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/generated/assets.gen.dart';

enum TokenizedCommunityTabType implements TabType {
  chart,
  holders,
  trades,
  comments;

  @override
  String get iconAsset {
    return switch (this) {
      TokenizedCommunityTabType.chart => Assets.svg.iconCreatecoinNewcoin,
      TokenizedCommunityTabType.holders => Assets.svg.iconSearchGroups,
      TokenizedCommunityTabType.trades => Assets.svg.fluentArrowSort16Regular,
      TokenizedCommunityTabType.comments => Assets.svg.iconBlockComment,
    };
  }

  @override
  String getTitle(BuildContext context) {
    switch (this) {
      case TokenizedCommunityTabType.chart:
        return context.i18n.tokenized_community_chart_tab;
      case TokenizedCommunityTabType.holders:
        return context.i18n.tokenized_community_holders_tab;
      case TokenizedCommunityTabType.trades:
        return context.i18n.tokenized_community_trades_tab;
      case TokenizedCommunityTabType.comments:
        return context.i18n.tokenized_community_comments_tab;
    }
  }
}

class TokenizedCommunityPage extends HookConsumerWidget {
  const TokenizedCommunityPage({required this.externalAddress, super.key});

  final String externalAddress;

  static double get _expandedHeaderHeight => 350.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress));
    final tokenDefinition = ref
        .watch(tokenDefinitionForExternalAddressProvider(externalAddress: externalAddress))
        .valueOrNull;

    final token = tokenInfo.valueOrNull;

    if (token == null || tokenDefinition == null) {
      return const SizedBox.shrink();
    }

    final typeAsync = ref.watch(tokenTypeForExternalAddressProvider(externalAddress));

    final sectionKeys = useMemoized(
      () => List.generate(
        TokenizedCommunityTabType.values.length,
        (_) => GlobalKey(),
      ),
    );
    final tabCount = TokenizedCommunityTabType.values.length;

    // Hook for visibility logic - manages active tab index automatically
    final visibilityState = useSectionVisibilityController(tabCount);
    final visibilityCallbacks = visibilityState.callbacks;

    final scrollToSection = useMemoized(
      () => visibilityState.createScrollToSection(
        sectionKeys,
      ),
      [visibilityState, sectionKeys],
    );

    return CollapsingHeaderScrollLinksLayout(
      backgroundColor: context.theme.appColors.secondaryBackground,
      tabs: TokenizedCommunityTabType.values,
      sectionKeys: sectionKeys,
      activeIndex: visibilityState.activeIndex.value,
      onTabTapped: scrollToSection,
      expandedHeaderHeight: _expandedHeaderHeight,
      expandedHeader: Column(
        children: [
          SizedBox(height: MediaQuery.viewPaddingOf(context).top),
          if (typeAsync.valueOrNull != null)
            Builder(
              builder: (context) {
                final t = typeAsync.valueOrNull!;

                if (t == CommunityContentTokenType.profile) {
                  return ProfileTokenHeader(
                    token: token,
                    externalAddress: externalAddress,
                    minimal: true,
                  );
                } else if (t == CommunityContentTokenType.twitter) {
                  return TwitterTokenHeader(
                    token: token,
                    showBuyButton: false,
                  );
                } else {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: t == CommunityContentTokenType.postText ? 26.s : 0,
                    ),
                    child: ContentTokenHeader(
                      type: t,
                      token: token,
                      externalAddress: externalAddress,
                      tokenDefinition: tokenDefinition,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      imageUrl: token.imageUrl,
      actions: [
        IconButton(
          onPressed: () {
            //TODO (ice-kreios): navigate to bookmarks page
          },
          icon: Assets.svg.iconBookmarks.icon(
            size: 24.0.s,
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Assets.svg.iconMoreStoriesshadow.icon(
            size: 24.0.s,
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
      ],
      sectionsBuilder: (keys) => [
        // Chart section
        KeyedSubtree(
          key: keys[0],
          child: Column(
            children: [
              SimpleSeparator(height: 4.0.s),
              YourPositionCard(
                token: token,
                trailing: SimpleSeparator(height: 4.0.s),
              ),
              _TokenChart(
                externalAddress: externalAddress,
                onTitleVisibilityChanged: visibilityCallbacks[0],
              ),
              SimpleSeparator(height: 4.0.s),
              _TokenStats(externalAddress: externalAddress),
              SimpleSeparator(height: 4.0.s),
            ],
          ),
        ),
        // Holders section
        KeyedSubtree(
          key: keys[1],
          child: Column(
            children: [
              TopHolders(
                externalAddress: externalAddress,
                onTitleVisibilityChanged: visibilityCallbacks[1],
              ),
              SimpleSeparator(height: 4.0.s),
            ],
          ),
        ),
        // Trades section
        KeyedSubtree(
          key: keys[2],
          child: Column(
            children: [
              LatestTradesCard(
                externalAddress: externalAddress,
                onTitleVisibilityChanged: visibilityCallbacks[2],
              ),
              SimpleSeparator(height: 4.0.s),
            ],
          ),
        ),
        // Comments section
        KeyedSubtree(
          key: keys[3],
          child: Column(
            children: [
              CommentsSectionCompact(
                commentCount: 10,
                onTitleVisibilityChanged: visibilityCallbacks[3],
              ),
              SizedBox(height: 120.0.s),
            ],
          ),
        ),
      ],
      collapsedTitle: SizedBox(
        height: 36.s,
        child: Row(
          children: [
            CommunityTokenImage(
              imageUrl: token.imageUrl,
              width: 36.s,
              height: 36.s,
              innerBorderRadius: 10.s,
              outerBorderRadius: 10.s,
              innerPadding: 0.s,
            ),
            SizedBox(
              width: 8.s,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      token.title,
                      style: context.theme.appTextThemes.subtitle3.copyWith(
                        color: context.theme.appColors.onPrimaryAccent,
                      ),
                    ),
                  ],
                ),
                Text(
                  token.marketData.ticker ?? '',
                  style: context.theme.appTextThemes.caption.copyWith(
                    color: context.theme.appColors.attentionBlock,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingTradeIsland(externalAddress: externalAddress),
    );
  }
}

class _TokenChart extends HookConsumerWidget {
  const _TokenChart({
    required this.externalAddress,
    required this.onTitleVisibilityChanged,
  });

  final String externalAddress;
  final ValueChanged<double>? onTitleVisibilityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress));
    final token = tokenInfo.valueOrNull;

    // If token info is not yet available, render nothing (unchanged behaviour).
    if (token == null) {
      return const SizedBox.shrink();
    }

    final price = Decimal.parse(token.marketData.priceUSD.toStringAsFixed(4));

    return Chart(
      externalAddress: externalAddress,
      price: price,
      label: token.title,
      onTitleVisibilityChanged: onTitleVisibilityChanged,
    );
  }
}

class _TokenStats extends HookConsumerWidget {
  const _TokenStats({required this.externalAddress});

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTimeframe = useState(0);
    final tradingStatsAsync = ref.watch(tokenTradingStatsProvider(externalAddress));

    return tradingStatsAsync.when(
      data: (tradingStats) {
        // Get the selected timeframe's stats
        // Sort entries by timeframe duration (5m, 1h, 6h, 24h, etc.)
        final timeframeEntries = tradingStats.entries.toList()
          ..sort(
            (a, b) => a.key.sortValue.compareTo(b.key.sortValue),
          );

        final selectedTimeframeStats = timeframeEntries[selectedTimeframe.value].value;
        final selectedStatsFormatted = TradingStatsFormatted.fromStats(selectedTimeframeStats);

        return ChartStats(
          selectedTimeframe: selectedTimeframe.value,
          timeframes: [
            for (final timeframeEntry in timeframeEntries)
              TimeframeChange(
                label: timeframeEntry.key.displayLabel,
                percent: timeframeEntry.value.netBuyPercent,
              ),
          ],
          volumeText: selectedStatsFormatted.volumeText,
          buysText: selectedStatsFormatted.buysText,
          sellsText: selectedStatsFormatted.sellsText,
          netBuyText: selectedStatsFormatted.netBuyText,
          //TODO: handle this new prop
          // isNetBuyPositive: selectedStatsFormatted.isNetBuyPositive,
          isNetBuyPositive: true,
          onTimeframeTap: (index) => selectedTimeframe.value = index,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }
}
