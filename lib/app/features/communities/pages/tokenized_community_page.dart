// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_tabs_layout.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/models/latest_trade.dart';
import 'package:ion/app/features/communities/models/top_holder.dart';
import 'package:ion/app/features/communities/models/trading_stats_formatted.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_olhcv_candles_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_trading_stats_provider.r.dart';
import 'package:ion/app/features/communities/utils/timeframe_extension.dart';
import 'package:ion/app/features/communities/utils/trading_stats_extension.dart';
import 'package:ion/app/features/communities/views/components/chart_component.dart';
import 'package:ion/app/features/communities/views/components/chart_stats_component.dart';
import 'package:ion/app/features/communities/views/components/comments_section_compact.dart';
import 'package:ion/app/features/communities/views/components/latest_trades_component.dart';
import 'package:ion/app/features/communities/views/components/token_header_component.dart';
import 'package:ion/app/features/communities/views/components/top_holders_component.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/header.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_actions/profile_action.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

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

class TokenizedCommunityPage extends HookWidget {
  const TokenizedCommunityPage({required this.masterPubkey, super.key});

  final String masterPubkey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      extendBodyBehindAppBar: true,
      body: CollapsingHeaderTabsLayout(
        backgroundColor: context.theme.appColors.secondaryBackground,
        avatarUrl: null,
        tabs: TokenizedCommunityTabType.values,
        headerActionsBuilder: (menuCloseSignal) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAction(
              profileMode: ProfileMode.dark,
              assetName: Assets.svg.iconBookmarks,
              onPressed: () {},
            ),
            SizedBox(width: 12.0.s),
            ProfileAction(
              profileMode: ProfileMode.dark,
              assetName: Assets.svg.iconMoreStoriesshadow,
              onPressed: () {},
            ),
          ],
        ),
        tabBarViews: [
          _ChartsTabView(masterPubkey: masterPubkey),
          _TopHolders(),
          _LatestTrades(),
          const CommentsSectionCompact(commentCount: 10),
        ],
        collapsedHeaderBuilder: (opacity) => Header(
          pubkey: '',
          opacity: opacity,
          showBackButton: true,
          textColor: context.theme.appColors.secondaryBackground,
        ),
        expandedHeader: _TokenExpandedHeader(masterPubkey: masterPubkey),
      ),
    );
  }
}

class _ChartsTabView extends StatelessWidget {
  const _ChartsTabView({required this.masterPubkey});

  final String masterPubkey;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _TokenChart(masterPubkey: masterPubkey)),
        SliverToBoxAdapter(child: HorizontalSeparator(height: 4.0.s)),
        SliverToBoxAdapter(child: _TokenStats(masterPubkey: masterPubkey)),
        SliverToBoxAdapter(child: HorizontalSeparator(height: 4.0.s)),
        SliverToBoxAdapter(child: _TopHolders()),
        SliverToBoxAdapter(child: HorizontalSeparator(height: 4.0.s)),
        SliverToBoxAdapter(child: _LatestTrades()),
        SliverToBoxAdapter(child: HorizontalSeparator(height: 4.0.s)),
        const SliverToBoxAdapter(
          child: CommentsSectionCompact(commentCount: 10),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 120.0.s)),
      ],
    );
  }
}

class _TokenExpandedHeader extends ConsumerWidget {
  const _TokenExpandedHeader({required this.masterPubkey});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(masterPubkey));
    final token = tokenInfo.valueOrNull;

    return TokenHeaderComponent(
      token: token,
      masterPubkey: masterPubkey,
    );
  }
}

class _TokenChart extends HookConsumerWidget {
  const _TokenChart({required this.masterPubkey});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = useState(ChartTimeRange.m15);
    final tokenInfo = ref.watch(tokenMarketInfoProvider(masterPubkey));
    final token = tokenInfo.valueOrNull;

    final candles = ref.watch(
      tokenOhlcvCandlesProvider(
        masterPubkey,
        selectedRange.value.intervalString,
      ),
    );

    return candles.when(
      data: (candles) {
        // Use token data if available, otherwise show loading/placeholder
        if (token == null) {
          return const SizedBox.shrink();
        }

        return ChartComponent(
          price: Decimal.parse(token.marketData.priceUSD.toStringAsFixed(4)),
          label: token.title,
          changePercent: 145.84, // TODO: Calculate from candles
          candles: mapOhlcvToChartCandles(candles),
          selectedRange: selectedRange.value,
          onRangeChanged: (range) => selectedRange.value = range,
        );
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

extension on ChartTimeRange {
  String get intervalString => switch (this) {
        ChartTimeRange.m1 => '1m',
        ChartTimeRange.m3 => '3m',
        ChartTimeRange.m5 => '5m',
        ChartTimeRange.m15 => '15m',
        ChartTimeRange.m30 => '30m',
        ChartTimeRange.h1 => '1h',
        ChartTimeRange.d1 => '1d',
      };
}

class _TokenStats extends HookConsumerWidget {
  const _TokenStats({required this.masterPubkey});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTimeframe = useState(0);
    final tradingStatsAsync = ref.watch(tokenTradingStatsProvider(masterPubkey));

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

        return ChartStatsComponent(
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
          isNetBuyPositive: selectedStatsFormatted.isNetBuyPositive,
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

class _TopHolders extends HookWidget {
  @override
  Widget build(BuildContext context) {
    const holders = [
      TopHolder(
        displayName: 'Stephan Chan',
        handle: '@stepchan',
        amount: 10200000,
        percentShare: 10.22,
      ),
      TopHolder(displayName: 'Jane Doe', handle: '@janedoe', amount: 10520000, percentShare: 10.22),
      TopHolder(
        displayName: 'Alex Smith',
        handle: '@alexsmith',
        amount: 15000000,
        percentShare: 8.67,
      ),
      TopHolder(displayName: '0x565gj...9cid4j', handle: '', amount: 25520000, percentShare: 0.91),
      TopHolder(displayName: '0x987gj...9cid4j', handle: '', amount: 12502, percentShare: 0.76),
    ];

    return TopHoldersComponent(
      holders: holders,
      onViewAllPressed: () {},
    );
  }
}

class _LatestTrades extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final trades = [
      LatestTrade(
        displayName: 'Mike Jay Evans',
        handle: '@mikejayevans',
        amount: 2340,
        usd: 6.81,
        time: now.subtract(const Duration(minutes: 23)),
        side: TradeSide.buy,
        verified: true,
      ),
      LatestTrade(
        displayName: 'Samuel Smith',
        handle: '@samuelsmith',
        amount: 98110,
        usd: 987,
        time: now.subtract(const Duration(minutes: 45)),
        side: TradeSide.sell,
      ),
      LatestTrade(
        displayName: 'Saul Bettings',
        handle: '@saulbettings',
        amount: 1120,
        usd: 137,
        time: now.subtract(const Duration(minutes: 56)),
        side: TradeSide.buy,
      ),
      LatestTrade(
        displayName: '0x987gj...9cid4j',
        handle: '',
        amount: 0,
        usd: 0,
        time: now.subtract(const Duration(minutes: 70)),
        side: TradeSide.buy,
      ),
      LatestTrade(
        displayName: '0x987gj...9cid4j',
        handle: '',
        amount: 0,
        usd: 0,
        time: now.subtract(const Duration(minutes: 85)),
        side: TradeSide.sell,
        verified: true,
      ),
    ];

    return LatestTradesComponent(
      trades: trades,
      onViewAllPressed: () {},
    );
  }
}

List<ChartCandle> mapOhlcvToChartCandles(List<OhlcvCandle> source) {
  return source
      .map(
        (candle) => ChartCandle(
          open: candle.open,
          high: candle.high,
          low: candle.low,
          close: candle.close,
          price: Decimal.parse(candle.close.toString()),
          date: DateTime.fromMillisecondsSinceEpoch(
            (candle.timestamp ~/ 1000), // timestamp is in microseconds
            isUtc: true,
          ),
        ),
      )
      .toList();
}
