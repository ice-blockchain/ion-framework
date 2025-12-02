// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_scroll_links_layout.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/hooks/section_visibility_controller.dart';
import 'package:ion/app/features/communities/models/trading_stats_formatted.dart';
import 'package:ion/app/features/communities/pages/components/your_position_card.dart';
import 'package:ion/app/features/communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/communities/providers/token_trading_stats_provider.r.dart';
import 'package:ion/app/features/communities/utils/timeframe_extension.dart';
import 'package:ion/app/features/communities/utils/trading_stats_extension.dart';
import 'package:ion/app/features/communities/views/components/chart_component.dart';
import 'package:ion/app/features/communities/views/components/chart_stats_component.dart';
import 'package:ion/app/features/communities/views/components/comments_section_compact.dart';
import 'package:ion/app/features/communities/views/components/floating_trade_island.dart';
import 'package:ion/app/features/communities/views/components/latest_trades_component.dart';
import 'package:ion/app/features/communities/pages/holders/components/top_holders/top_holders.dart';
import 'package:ion/app/features/communities/views/components/token_header_component.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/app/features/user/pages/components/profile_avatar/profile_avatar.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';
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
  const TokenizedCommunityPage({required this.masterPubkey, super.key});

  final String masterPubkey;

  static double get _expandedHeaderHeight => 316.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get token from provider (like HEAD does)
    final tokenInfo = ref.watch(tokenMarketInfoProvider(masterPubkey));
    final token = tokenInfo.valueOrNull;

    // Create keys for each section to enable scroll-to-section navigation
    final sectionKeys = useMemoized(
      () => List.generate(TokenizedCommunityTabType.values.length, (_) => GlobalKey()),
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
      externalActiveIndex: visibilityState.activeIndex,
      onTabTapped: scrollToSection,
      expandedHeaderHeight: _expandedHeaderHeight,
      expandedHeader: TokenHeaderComponent(
        token: token,
        masterPubkey: masterPubkey,
      ),
      actions: [
        IconButton(
          onPressed: () {},
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
              YourPositionCard(masterPubkey: masterPubkey),
              // TODO: remove, just for entering & debugging global categories page
              Padding(
                padding: EdgeInsets.all(16.0.s),
                child: TextButton(
                  onPressed: () =>
                      CreatorTokensRoute(masterPubkey: masterPubkey).push<void>(context),
                  child: Text(context.i18n.core_view_all),
                ),
              ),
              _TokenChart(
                masterPubkey: masterPubkey,
                onTitleVisibilityChanged: visibilityCallbacks[0],
              ),
              HorizontalSeparator(height: 4.0.s),
              _TokenStats(masterPubkey: masterPubkey),
              HorizontalSeparator(height: 4.0.s),
            ],
          ),
        ),
        // Holders section
        KeyedSubtree(
          key: keys[1],
          child: Column(
            children: [
              TopHolders(
                masterPubkey: masterPubkey,
                onTitleVisibilityChanged: visibilityCallbacks[1],
              ),
              HorizontalSeparator(height: 4.0.s),
            ],
          ),
        ),
        // Trades section
        KeyedSubtree(
          key: keys[2],
          child: Column(
            children: [
              _LatestTrades(
                masterPubkey: masterPubkey,
                onTitleVisibilityChanged: visibilityCallbacks[2],
              ),
              HorizontalSeparator(height: 4.0.s),
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
      collapsedTitle: _CollapsedTitle(masterPubkey: masterPubkey),
      floatingActionButton: FloatingTradeIsland(pubkey: masterPubkey),
    );
  }
}

// Collapsed title shown when app bar is collapsed - shows avatar, name, and handle
class _CollapsedTitle extends ConsumerWidget {
  const _CollapsedTitle({required this.masterPubkey});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(masterPubkey));
    final token = tokenInfo.valueOrNull;

    if (token == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        ProfileAvatar(
          pubkey: masterPubkey,
          size: 32.0.s,
        ),
        SizedBox(width: 8.0.s),
        // Name and handle
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  token.creator.display,
                  style: context.theme.appTextThemes.subtitle2.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (token.creator.verified) ...[
                  SizedBox(width: 4.0.s),
                  Assets.svg.iconBadgeVerify.icon(size: 18.0.s),
                ],
              ],
            ),
            Text(
              prefixUsername(username: token.creator.name, context: context),
              style: context.theme.appTextThemes.caption3.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TokenChart extends HookConsumerWidget {
  const _TokenChart({
    required this.masterPubkey,
    this.onTitleVisibilityChanged,
  });

  final String masterPubkey;
  final ValueChanged<double>? onTitleVisibilityChanged;

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
      onTitleVisibilityChanged: onTitleVisibilityChanged,
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

class _LatestTrades extends HookConsumerWidget {
  const _LatestTrades({
    required this.masterPubkey,
    this.onTitleVisibilityChanged,
  });

  static const int limit = 5;

  final String masterPubkey;
  final ValueChanged<double>? onTitleVisibilityChanged;

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
          onTitleVisibilityChanged: onTitleVisibilityChanged,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }
}
