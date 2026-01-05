// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_layout.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/components/tabs_header/scroll_links_tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/bookmarks/bookmark_button.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_content_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_profile_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_twitter_token.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/trading_stats_formatted.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_trading_stats_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/timeframe_extension.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart_stats.dart';
import 'package:ion/app/features/tokenized_communities/views/components/comments_section_compact.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_context_menu.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_image.dart';
import 'package:ion/app/features/tokenized_communities/views/components/floating_trade_island.dart';
import 'package:ion/app/features/tokenized_communities/views/components/your_position_card.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/top_holders/top_holders.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/providers/token_top_holders_provider.r.dart';
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
  const TokenizedCommunityPage({
    required this.externalAddress,
    super.key,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;
    final tokenDefinition = ref
        .watch(tokenDefinitionForExternalAddressProvider(externalAddress: externalAddress))
        .valueOrNull;
    final tokenType = ref.watch(tokenTypeForExternalAddressProvider(externalAddress)).valueOrNull;
    final activeTab = useState(TokenizedCommunityTabType.chart);
    final isCommentInputFocused = useState(false);
    final innerScrollController = useState<ScrollController?>(null);

    final sectionKeys = useMemoized(
      () => List.generate(
        TokenizedCommunityTabType.values.length,
        (_) => GlobalKey(),
      ),
      [],
    );

    Future<void> scrollToSection(int index) async {
      final targetCtx = sectionKeys[index].currentContext;
      if (targetCtx == null) return;

      final nestedState = targetCtx.findAncestorStateOfType<NestedScrollViewState>();
      final inner = nestedState?.innerController ?? innerScrollController.value;
      if (inner == null || !inner.hasClients) return;

      final ro = targetCtx.findRenderObject();
      if (ro == null) return;

      final viewport = RenderAbstractViewport.of(ro);

      // Align the section to the TOP of the inner viewport.
      final desired = viewport.getOffsetToReveal(ro, 0).offset;
      final pos = inner.position;
      final target = (desired - 110.0).clamp(pos.minScrollExtent, pos.maxScrollExtent);

      await inner.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return CollapsingHeaderLayout(
      backgroundColor: context.theme.appColors.secondaryBackground,
      applySafeAreaBottomPadding: false,
      imageUrl: tokenInfo?.imageUrl,
      pinnedHeader: SizedBox(
        height: 40.0.s,
        child: ScrollLinksTabsHeader(
          tabs: TokenizedCommunityTabType.values,
          activeIndex: activeTab.value.index,
          onTabTapped: (int index) {
            activeTab.value = TokenizedCommunityTabType.values[index];
            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToSection(index);
            });
          },
        ),
      ),
      onRefresh: () async {
        ref
          ..invalidate(tokenMarketInfoProvider(externalAddress))
          ..invalidate(tokenTradingStatsProvider(externalAddress))
          ..invalidate(tokenLatestTradesProvider(externalAddress, limit: LatestTradesCard.limit))
          ..invalidate(tokenTopHoldersProvider(externalAddress, limit: holdersCountLimit));
      },
      onInnerScrollController: (c) => innerScrollController.value = c,
      collapsedHeaderBuilder: (opacity) => SizedBox(
        height: 36.s,
        child: Row(
          children: [
            CommunityTokenImage(
              imageUrl: tokenInfo?.imageUrl,
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
                      tokenInfo?.title ?? '',
                      style: context.theme.appTextThemes.subtitle3.copyWith(
                        color: context.theme.appColors.onPrimaryAccent,
                      ),
                    ),
                  ],
                ),
                Text(
                  tokenInfo?.marketData.ticker ?? '',
                  style: context.theme.appTextThemes.caption.copyWith(
                    color: context.theme.appColors.attentionBlock,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: isCommentInputFocused.value
          ? const SizedBox.shrink()
          : FloatingTradeIsland(
              externalAddress: externalAddress,
            ),
      headerActionsBuilder: (OverlayMenuCloseSignal menuCloseSignal) => [
        if (tokenType == CommunityContentTokenType.profile)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 6.0.s),
            child: BookmarkButton(
              eventReference: ReplaceableEventReference.fromString(externalAddress),
              mode: BookmarkButtonMode.iconButton,
            ),
          ),
        CommunityTokenContextMenu(
          closeSignal: menuCloseSignal,
          tokenDefinitionEntity: tokenDefinition,
        ),
        SizedBox(width: 16.s),
      ],
      expandedHeader: Column(
        children: [
          SizedBox(height: MediaQuery.viewPaddingOf(context).top + 16.s),
          if (tokenType != null)
            Builder(
              builder: (context) {
                if (tokenInfo == null) {
                  return const SizedBox.shrink();
                }

                if (tokenType == CommunityContentTokenType.profile) {
                  return ProfileTokenHeader(
                    token: tokenInfo,
                    externalAddress: externalAddress,
                    minimal: true,
                  );
                } else if (tokenType == CommunityContentTokenType.twitter) {
                  return TwitterTokenHeader(
                    token: tokenInfo,
                    showBuyButton: false,
                  );
                } else {
                  if (tokenDefinition == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: tokenType == CommunityContentTokenType.postText ? 36.s : 0,
                    ),
                    child: ContentTokenHeader(
                      type: tokenType,
                      token: tokenInfo,
                      externalAddress: externalAddress,
                      tokenDefinition: tokenDefinition,
                      showBuyButton: false,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      child: Column(
        children: [
          SimpleSeparator(height: 4.0.s),
          if (tokenInfo != null && tokenInfo.marketData.position != null)
            YourPositionCard(
              token: tokenInfo,
              trailing: SimpleSeparator(height: 4.0.s),
            ),
          KeyedSubtree(
            key: sectionKeys[TokenizedCommunityTabType.chart.index],
            child: _TokenChart(
              externalAddress: externalAddress,
            ),
          ),
          SimpleSeparator(height: 4.0.s),
          _TokenStats(externalAddress: externalAddress),
          SimpleSeparator(height: 4.0.s),
          KeyedSubtree(
            key: sectionKeys[TokenizedCommunityTabType.holders.index],
            child: TopHolders(
              externalAddress: externalAddress,
            ),
          ),
          SimpleSeparator(height: 4.0.s),
          KeyedSubtree(
            key: sectionKeys[TokenizedCommunityTabType.trades.index],
            child: LatestTradesCard(
              externalAddress: externalAddress,
            ),
          ),
          if (tokenDefinition != null) ...[
            SimpleSeparator(height: 4.0.s),
            KeyedSubtree(
              key: sectionKeys[TokenizedCommunityTabType.comments.index],
              child: CommentsSectionCompact(
                tokenDefinitionEventReference: tokenDefinition.toEventReference(),
                onCommentInputFocusChanged: (bool isFocused) {
                  isCommentInputFocused.value = isFocused;
                },
              ),
            ),
          ],
          SizedBox(height: 120.0.s),
        ],
      ),
    );
  }
}

class _TokenChart extends HookConsumerWidget {
  const _TokenChart({
    required this.externalAddress,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;

    // If token info is not yet available, render nothing (unchanged behaviour).
    if (tokenInfo == null) {
      return const SizedBox.shrink();
    }

    final price = Decimal.parse(tokenInfo.marketData.priceUSD.toStringAsFixed(4));

    return Chart(
      externalAddress: externalAddress,
      price: price,
      label: tokenInfo.marketData.ticker?.toUpperCase() ?? '',
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

        if (timeframeEntries.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedTimeframeStats = timeframeEntries[selectedTimeframe.value].value;
        final selectedStatsFormatted = TradingStatsFormatted.fromStats(selectedTimeframeStats);

        return ChartStats(
          selectedTimeframe: selectedTimeframe.value,
          timeframes: [
            for (final timeframeEntry in timeframeEntries)
              TimeframeChange(
                label: timeframeEntry.key.displayLabel,
                percent: timeframeEntry.value.priceDiff,
              ),
          ],
          volumeText: selectedStatsFormatted.volumeText,
          buysText: selectedStatsFormatted.buysText,
          sellsText: selectedStatsFormatted.sellsText,
          netBuyText: selectedStatsFormatted.netBuyText,
          isNetBuyPositive: selectedStatsFormatted.isNetBuyPositive,
          hasNoSells: selectedStatsFormatted.hasNoSells,
          hasZeroNetBuy: selectedStatsFormatted.hasZeroNetBuy,
          onTimeframeTap: (index) => selectedTimeframe.value = index,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
