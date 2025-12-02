// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_tabs_layout.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/models/trading_stats_formatted.dart';
import 'package:ion/app/features/communities/pages/components/your_position_card.dart';
import 'package:ion/app/features/communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
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
import 'package:ion/app/router/app_routes.gr.dart';
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
          pubkey: masterPubkey,
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
        SliverToBoxAdapter(child: YourPositionCard(masterPubkey: masterPubkey)),
        // TODO: remove, just for enterign global categories page
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.0.s),
            child: TextButton(
              onPressed: () {
                CreatorTokensRoute(masterPubkey: masterPubkey).push<void>(context);
              },
              child: const Text('View Global Categories'),
            ),
          ),
        ),
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
    final tokenInfo = ref.watch(tokenMarketInfoProvider(masterPubkey));
    final token = tokenInfo.valueOrNull;

    // If token info is not yet available, render nothing (unchanged behaviour).
    if (token == null) {
      return const SizedBox.shrink();
    }

    final price = Decimal.parse(token.marketData.priceUSD.toStringAsFixed(4));

    return ChartComponent(
      masterPubkey: masterPubkey,
      price: price,
      label: token.title,
    );
  }
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

class _TopHolders extends HookConsumerWidget {
  const _TopHolders({required this.masterPubkey});

  static const int limit = 5;

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdersAsync = ref.watch(tokenTopHoldersProvider(masterPubkey, limit: limit));

    return holdersAsync.when(
      data: (holders) {
        if (holders.isEmpty) {
          return const SizedBox.shrink();
        }
        return TopHoldersComponent(
          holders: holders,
          onViewAllPressed: () {},
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LatestTrades extends HookConsumerWidget {
  const _LatestTrades({required this.masterPubkey});

  static const int limit = 5;

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tokenLatestTradesProvider(masterPubkey, limit: limit));

    return tradesAsync.when(
      data: (trades) {
        if (trades.isEmpty) {
          return const SizedBox.shrink();
        }
        return LatestTradesComponent(
          trades: trades,
          onViewAllPressed: () {},
          onLoadMore: () => ref.read(tokenLatestTradesProvider(masterPubkey).notifier).loadMore(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }
}
