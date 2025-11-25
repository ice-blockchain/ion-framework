// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/layouts/collapsing_header_tabs_layout.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/models/latest_trade.dart';
import 'package:ion/app/features/communities/models/token_header_data.dart';
import 'package:ion/app/features/communities/models/top_holder.dart';
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
  const TokenizedCommunityPage({super.key});

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
          const _ChartsTabView(),
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
        expandedHeader: const _TokenExpandedHeader(),
      ),
    );
  }
}

class _ChartsTabView extends StatelessWidget {
  const _ChartsTabView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _TokenChart()),
        SliverToBoxAdapter(child: HorizontalSeparator(height: 4.0.s)),
        SliverToBoxAdapter(child: _TokenStats()),
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

class _TokenExpandedHeader extends StatelessWidget {
  const _TokenExpandedHeader();
  @override
  Widget build(BuildContext context) {
    const headerData = TokenHeaderData(
      displayName: 'Susan Hellena Parks',
      handle: '@susan_h_parks',
      priceUsd: 0.0000117,
      marketCapUsd: 43230000,
      holdersCount: 1100,
      volumeUsd: 990,
      verified: true,
    );
    return const TokenHeaderComponent(data: headerData);
  }
}

class _TokenChart extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedRange = useState(ChartTimeRange.m15);

    return ChartComponent(
      price: Decimal.parse('0.0234'),
      label: 'SUSAN H PARKS',
      changePercent: 145.84,
      candles: demoCandles,
      selectedRange: selectedRange.value,
      onRangeChanged: (range) => selectedRange.value = range,
    );
  }
}

class _TokenStats extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedTimeframe = useState(0);

    return ChartStatsComponent(
      selectedTimeframe: selectedTimeframe.value,
      timeframes: const [
        TimeframeChange(label: '5m', percent: -0.55),
        TimeframeChange(label: '1h', percent: -0.55),
        TimeframeChange(label: '6h', percent: 44.43),
        TimeframeChange(label: '24h', percent: 1244.99),
      ],
      volumeText: r'$140.6K',
      buysText: r'154/$154K',
      sellsText: r'145/$153K',
      netBuyText: '+18K',
      onTimeframeTap: (index) => selectedTimeframe.value = index,
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
