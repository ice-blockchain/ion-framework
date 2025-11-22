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
import 'package:ion/app/features/communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_olhcv_candles_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_top_holders_provider.r.dart';
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
          _TopHolders(masterPubkey: masterPubkey),
          _LatestTrades(masterPubkey: masterPubkey),
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
        SliverToBoxAdapter(child: _TopHolders(masterPubkey: masterPubkey)),
        SliverToBoxAdapter(child: HorizontalSeparator(height: 4.0.s)),
        SliverToBoxAdapter(child: _LatestTrades(masterPubkey: masterPubkey)),
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

class _TopHolders extends HookConsumerWidget {
  const _TopHolders({required this.masterPubkey});

  static const int limit = 5;

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdersAsync = ref.watch(tokenTopHoldersProvider(masterPubkey, limit: limit));

    return holdersAsync.when(
      data: (holders) {
        final holderViewData = holders.map<TopHolderViewData>(_mapToHolderViewData).toList();
        if (holderViewData.isEmpty) {
          return const SizedBox.shrink();
        }
        return TopHoldersComponent(
          holders: holderViewData,
          onViewAllPressed: () {},
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  TopHolderViewData _mapToHolderViewData(TopHolder holder) {
    final profile = holder.position.holder;
    final handle = profile.name.isNotEmpty ? '@${profile.name}' : '';

    return TopHolderViewData(
      displayName: profile.display,
      handle: handle,
      amount: holder.position.amount,
      percentShare: holder.position.supplyShare,
      avatarUrl: profile.avatar,
    );
  }
}

class _LatestTrades extends HookConsumerWidget {
  const _LatestTrades({required this.masterPubkey});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tokenLatestTradesProvider(masterPubkey));

    return tradesAsync.when(
      data: (trades) {
        final tradesViewData = trades.map(LatestTradeViewData.fromLatestTrade).toList();
        if (tradesViewData.isEmpty) {
          return const SizedBox.shrink();
        }
        return LatestTradesComponent(
          trades: tradesViewData,
          onViewAllPressed: () {},
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) {
        return const SizedBox.shrink();
      },
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
            candle.timestamp ~/ 1000, // timestamp is in microseconds
            isUtc: true,
          ),
        ),
      )
      .toList();
}
