// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_layout.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/components/tabs_header/scroll_links_tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
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
import 'package:ion/app/features/tokenized_communities/utils/trading_stats_extension.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart_stats.dart';
import 'package:ion/app/features/tokenized_communities/views/components/comments_section_compact.dart';
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
    this.eventReference,
    this.externalAddress,
    super.key,
  }) : assert(
          (eventReference == null) != (externalAddress == null),
          'Either eventReference or externalAddress must be provided',
        );

  final EventReference? eventReference;
  final String? externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedExternalAddress = externalAddress ?? eventReference!.toString();
    final tokenInfo = ref.watch(tokenMarketInfoProvider(resolvedExternalAddress)).valueOrNull;
    final tokenDefinition = (eventReference != null
            ? ref.watch(
                tokenDefinitionForIonConnectReferenceProvider(eventReference: eventReference!),
              )
            : ref.watch(
                tokenDefinitionForExternalAddressProvider(externalAddress: externalAddress!),
              ))
        .valueOrNull;

    final tokenType = (eventReference != null
            ? ref.watch(tokenTypeForIonConnectEntityProvider(eventReference: eventReference!))
            : ref.watch(tokenTypeForExternalAddressProvider(externalAddress!)))
        .valueOrNull;
    final activeTab = useState(TokenizedCommunityTabType.chart);
    final isCommentInputFocused = useState(false);

    final sectionKeys = useMemoized(
      () => List.generate(
        TokenizedCommunityTabType.values.length,
        (_) => GlobalKey(),
      ),
      [],
    );

    return CollapsingHeaderLayout(
      backgroundColor: context.theme.appColors.secondaryBackground,
      applySafeAreaBottomPadding: false,
      imageUrl: tokenInfo?.imageUrl,
      onRefresh: () async {
        final externalAddress = this.externalAddress ?? eventReference!.toString();

        ref
          ..invalidate(tokenMarketInfoProvider(externalAddress))
          ..invalidate(tokenTradingStatsProvider(externalAddress))
          ..invalidate(tokenLatestTradesProvider(externalAddress, limit: LatestTradesCard.limit))
          ..invalidate(tokenTopHoldersProvider(externalAddress, limit: holdersCountLimit));
      },
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
              eventReference: eventReference,
              externalAddress: externalAddress,
            ),
      headerActionsBuilder: (OverlayMenuCloseSignal menuCloseSignal) => [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            //TODO (ice-kreios): navigate to bookmarks page
          },
          icon: Assets.svg.iconBookmarks.icon(
            size: 24.s,
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          icon: Assets.svg.iconMoreStoriesshadow.icon(
            size: 24.s,
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
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
                    externalAddress: resolvedExternalAddress,
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
                      externalAddress: resolvedExternalAddress,
                      tokenDefinition: tokenDefinition,
                      showBuyButton: false,
                    ),
                  );
                }
              },
            ),
          SizedBox(height: 16.0.s),
          ScrollLinksTabsHeader(
            tabs: TokenizedCommunityTabType.values,
            activeIndex: activeTab.value.index,
            onTabTapped: (int index) {
              activeTab.value = TokenizedCommunityTabType.values[index];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final context = sectionKeys[index].currentContext;
                if (context != null) {
                  Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: 0.1,
                  );
                }
              });
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
              externalAddress: resolvedExternalAddress,
              onTitleVisibilityChanged: (double visibility) {
                //do not handle with current implementation
              },
            ),
          ),
          SimpleSeparator(height: 4.0.s),
          _TokenStats(externalAddress: resolvedExternalAddress),
          SimpleSeparator(height: 4.0.s),
          TopHolders(
            key: sectionKeys[TokenizedCommunityTabType.holders.index],
            externalAddress: resolvedExternalAddress,
            onTitleVisibilityChanged: (double visibility) {
              //do not handle with current implementation
            },
          ),
          SimpleSeparator(height: 4.0.s),
          LatestTradesCard(
            key: sectionKeys[TokenizedCommunityTabType.trades.index],
            externalAddress: resolvedExternalAddress,
            onTitleVisibilityChanged: (double visibility) {
              //do not handle with current implementation
            },
          ),
          if (tokenDefinition != null) ...[
            SimpleSeparator(height: 4.0.s),
            CommentsSectionCompact(
              key: sectionKeys[TokenizedCommunityTabType.comments.index],
              tokenDefinitionEventReference: tokenDefinition.toEventReference(),
              onTitleVisibilityChanged: (double visibility) {
                //do not handle with current implementation
              },
              onCommentInputFocusChanged: (bool isFocused) {
                isCommentInputFocused.value = isFocused;
              },
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
    required this.onTitleVisibilityChanged,
  });

  final String externalAddress;
  final ValueChanged<double>? onTitleVisibilityChanged;

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
      label: tokenInfo.title,
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
