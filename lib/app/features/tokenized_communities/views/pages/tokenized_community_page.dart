// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_layout.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/components/tabs_header/scroll_links_tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/bookmarks/bookmark_button.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_content_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_profile_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_twitter_token.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/trading_stats_formatted.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_latest_trades_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_trading_stats_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/prefix_x_token_ticker.dart';
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
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion/l10n/i10n.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

enum TokenizedCommunityTabType implements TabType {
  chart,
  holders,
  trades,
  comments;

  @override
  String get iconAsset {
    return switch (this) {
      TokenizedCommunityTabType.chart => Assets.svg.iconCreatecoinProfit,
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
    final tradeEventReference = _useTradeEventReference(
      externalAddress: externalAddress,
      tokenDefinition: tokenDefinition,
    );

    final tokenType = ref.watch(tokenTypeForExternalAddressProvider(externalAddress)).valueOrNull;
    final activeTab = useState(TokenizedCommunityTabType.chart);
    final isCommentInputFocused = useMemoized(() => ValueNotifier<bool>(false), []);
    final innerScrollController = useState<ScrollController?>(null);
    final ignoreScrollUpdates = useState(false);
    final pendingTabIndex = useRef<int?>(null);

    useEffect(
      () {
        return isCommentInputFocused.dispose;
      },
      [isCommentInputFocused],
    );

    final sectionContexts = useMemoized(
      () => List<BuildContext?>.filled(
        TokenizedCommunityTabType.values.length,
        null,
      ),
      [],
    );

    useEffect(
      () {
        final controller = innerScrollController.value;
        if (controller == null) return null;

        void handleScroll() {
          if (ignoreScrollUpdates.value || !controller.hasClients) {
            return;
          }

          const collapsedHeaderOffset = 160.0; // AppBar + pinned tabs + spacing
          const expandedHeaderTabsOffset = 40.0; // Height of the pinned tabs row

          final nestedState =
              sectionContexts.first?.findAncestorStateOfType<NestedScrollViewState>();
          final outer = nestedState?.outerController;
          final offsetBias = outer != null && outer.hasClients && outer.position.pixels > 0
              ? collapsedHeaderOffset
              : expandedHeaderTabsOffset;
          final currentOffset = controller.position.pixels;
          if (currentOffset <= 0) {
            if (activeTab.value != TokenizedCommunityTabType.chart) {
              activeTab.value = TokenizedCommunityTabType.chart;
            }
            return;
          }
          int? newIndex;

          for (var i = 0; i < sectionContexts.length; i++) {
            final sectionContext = sectionContexts[i];
            if (sectionContext == null) continue;
            final renderObject = sectionContext.findRenderObject();
            if (renderObject == null) continue;
            final viewport = RenderAbstractViewport.of(renderObject);

            final sectionOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
            if (sectionOffset <= currentOffset + offsetBias) {
              newIndex = i;
            } else {
              break;
            }
          }

          if (newIndex != null && newIndex != activeTab.value.index) {
            final resolvedIndex = newIndex;
            if (pendingTabIndex.value == resolvedIndex) {
              return;
            }
            pendingTabIndex.value = resolvedIndex;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              if (pendingTabIndex.value != resolvedIndex) return;
              if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
                return;
              }
              activeTab.value = TokenizedCommunityTabType.values[resolvedIndex];
              pendingTabIndex.value = null;
            });
          }
        }

        controller.addListener(handleScroll);
        handleScroll();
        return () => controller.removeListener(handleScroll);
      },
      [innerScrollController.value, sectionContexts],
    );

    Future<void> scrollToSection(int index) async {
      ignoreScrollUpdates.value = true;
      try {
        final targetCtx = sectionContexts[index];
        if (targetCtx == null) return;

        double outerOffsetDy = 0;

        final nestedState = targetCtx.findAncestorStateOfType<NestedScrollViewState>();
        final inner = nestedState?.innerController ?? innerScrollController.value;
        if (inner == null || !inner.hasClients) return;

        final outer = nestedState?.outerController;
        if (outer != null && outer.hasClients) {
          outerOffsetDy = outer.position.pixels;
          final outerTarget =
              index == 0 ? outer.position.minScrollExtent : outer.position.maxScrollExtent;

          unawaited(
            outer.animateTo(
              outerTarget,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          );
          if (index == 0) {
            return;
          }
        }

        final updatedCtx = sectionContexts[index];
        if (updatedCtx == null) return;

        final ro = updatedCtx.findRenderObject();
        if (ro == null) return;

        final viewport = RenderAbstractViewport.of(ro);

        // Align the section to the TOP of the inner viewport.
        final desired = viewport.getOffsetToReveal(ro, 0).offset;
        final pos = inner.position;
        final target = (desired - (outerOffsetDy == 0 ? 40 : 160))
            .clamp(pos.minScrollExtent, pos.maxScrollExtent);

        await inner.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } finally {
        ignoreScrollUpdates.value = false;
      }
    }

    return CollapsingHeaderLayout(
      backgroundColor: context.theme.appColors.secondaryBackground,
      applySafeAreaBottomPadding: false,
      imageUrl: tokenInfo?.imageUrl,
      pinnedHeader: SizedBox(
        height: 40.0.s,
        child: Align(
          alignment: Alignment.bottomCenter,
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
              innerBorderRadius: 7.s,
              outerBorderRadius: 10.s,
              innerPadding: 1.5.s,
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
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: isCommentInputFocused,
        builder: (context, isFocused, _) {
          return isFocused
              ? const SizedBox.shrink()
              : tradeEventReference != null
                  ? FloatingTradeIsland(eventReference: tradeEventReference)
                  : FloatingTradeIsland(externalAddress: externalAddress);
        },
      ),
      headerActionsBuilder: (OverlayMenuCloseSignal menuCloseSignal) => [
        Padding(
          padding: EdgeInsetsDirectional.only(end: 6.0.s),
          child: BookmarkButton(
            eventReference: tokenDefinition?.toEventReference(),
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
          SizedBox(height: MediaQuery.viewPaddingOf(context).top + 20.s),
          Builder(
            builder: (context) {
              if (tokenInfo == null) {
                return const _TokenHeaderSkeleton();
              }

              return switch (tokenType) {
                CommunityContentTokenType.profile => ProfileTokenHeader(
                    token: tokenInfo,
                    externalAddress: externalAddress,
                    minimal: true,
                    showInfoModals: true,
                  ),
                CommunityContentTokenType.twitter => TwitterTokenHeader(
                    token: tokenInfo,
                    showBuyButton: false,
                    showInfoModals: true,
                  ),
                _ => tokenDefinition == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsetsDirectional.only(
                          top: tokenType == CommunityContentTokenType.postText ? 36.s : 0,
                        ),
                        child: ContentTokenHeader(
                          type: tokenType ?? CommunityContentTokenType.postText,
                          token: tokenInfo,
                          externalAddress: externalAddress,
                          tokenDefinition: tokenDefinition,
                          showBuyButton: false,
                        ),
                      ),
              };
            },
          ),
          SizedBox(height: 16.0.s),
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
          Builder(
            builder: (context) {
              sectionContexts[TokenizedCommunityTabType.chart.index] = context;
              return _TokenChart(
                externalAddress: externalAddress,
              );
            },
          ),
          SimpleSeparator(height: 4.0.s),
          _TokenStats(externalAddress: externalAddress),
          SimpleSeparator(height: 4.0.s),
          Builder(
            builder: (context) {
              sectionContexts[TokenizedCommunityTabType.holders.index] = context;
              return TopHolders(
                externalAddress: externalAddress,
              );
            },
          ),
          SimpleSeparator(height: 4.0.s),
          Builder(
            builder: (context) {
              sectionContexts[TokenizedCommunityTabType.trades.index] = context;
              return LatestTradesCard(
                externalAddress: externalAddress,
              );
            },
          ),
          if (tokenDefinition != null) ...[
            SimpleSeparator(height: 4.0.s),
            Builder(
              builder: (context) {
                sectionContexts[TokenizedCommunityTabType.comments.index] = context;
                return CommentsSectionCompact(
                  tokenDefinition: tokenDefinition,
                  onCommentInputFocusChanged: (bool isFocused) {
                    if (isCommentInputFocused.value != isFocused) {
                      isCommentInputFocused.value = isFocused;
                    }
                  },
                );
              },
            ),
          ],
          SizedBox(height: 120.0.s),
        ],
      ),
    );
  }
}

// For creator tokens: Returns "@nickname (ticker)" where ticker is lowercase.
// For content tokens: Returns ticker as is from BE
String? _normalizeChartTitle({
  required CommunityToken token,
  required BuildContext context,
}) {
  final ticker = token.marketData.ticker ?? '';

  if (token.source.isTwitter) {
    return prefixXTokenTicker(ticker);
  }

  if (token.type == CommunityTokenType.profile) {
    // Creator token: @nickname (ticker) in lowercase
    final nickname = token.creator.name;
    if (nickname == null || nickname.isEmpty) {
      return null;
    }

    final tickerLower = ticker.toLowerCase();
    final usernamePart = prefixUsername(username: nickname.toLowerCase(), context: context);
    final rtl = isRTL(context);

    if (tickerLower.isNotEmpty) {
      return rtl ? '($tickerLower) $usernamePart' : '$usernamePart ($tickerLower)';
    }

    return usernamePart;
  }

  // Content token: ticker as is from BE
  return ticker;
}

EventReference? _useTradeEventReference({
  required String externalAddress,
  required CommunityTokenDefinitionEntity? tokenDefinition,
}) {
  final parsedEventReference = useMemoized(
    () {
      try {
        return ReplaceableEventReference.fromString(externalAddress);
      } catch (_) {
        return null;
      }
    },
    [externalAddress],
  );

  return switch (tokenDefinition?.data) {
    CommunityTokenDefinitionIon(:final eventReference) => eventReference,
    _ => parsedEventReference,
  };
}

class _TokenHeaderSkeleton extends StatelessWidget {
  const _TokenHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Skeleton(
      baseColor: context.theme.appColors.onTertiaryFill.withValues(alpha: 0.5),
      // highlightColor: colors.profitGreen,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 5.s,
          ),
          // Avatar skeleton
          Container(
            width: 82.s,
            height: 82.s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.s),
              color: colors.primaryBackground,
            ),
          ),
          SizedBox(height: 16.0.s),
          // Title skeleton
          Container(
            width: 136.s,
            height: 20.s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.s),
              color: colors.primaryBackground,
            ),
          ),
          SizedBox(height: 5.0.s),
          // Username/price skeleton
          Container(
            width: 96.s,
            height: 16.s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.s),
              color: colors.primaryBackground,
            ),
          ),
          SizedBox(height: 16.0.s),
          // Token stats skeleton
          Container(
            width: 256.s,
            height: 44.s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.s),
              color: colors.primaryBackground,
            ),
          ),
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
    final chartLabel = _normalizeChartTitle(
      token: tokenInfo,
      context: context,
    );

    return Chart(
      externalAddress: externalAddress,
      price: price,
      label: chartLabel ?? '',
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
