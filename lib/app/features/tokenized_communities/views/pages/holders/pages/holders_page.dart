// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_tile.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/top_holders/components/top_holders_skeleton.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/providers/token_top_holders_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class HoldersPage extends HookConsumerWidget {
  const HoldersPage({required this.externalAddress, super.key});

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final isLoadingMore = useState(false);
    final hasMore = useState(true);

    final topHoldersProvider = tokenTopHoldersProvider(externalAddress, limit: 20);
    final topHoldersAsync = ref.watch(topHoldersProvider);
    final topHolders = topHoldersAsync.valueOrNull ?? const <TopHolder>[];
    final boundingCurveAddress = ref.watch(bondingCurveAddressProvider).valueOrNull;
    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(context.i18n.holders, style: context.theme.appTextThemes.subtitle2),
      ),
      body: Column(
        children: [
          const SimpleSeparator(),
          Expanded(
            child: LoadMoreBuilder(
              showIndicator: false,
              slivers: [
                if (topHoldersAsync.isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 16.s, vertical: 12.s),
                      child: TopHoldersSkeleton(count: 20, seperatorHeight: 14.s),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: topHolders.length,
                    itemBuilder: (context, index) {
                      final topPadding = index == 0 ? 12.s : 7.s;
                      final bottomPadding = 7.s;
                      final holder = topHolders[index];

                      if (boundingCurveAddress != null &&
                          holder.isBoundingCurve(boundingCurveAddress)) {
                        return _HoldersListPadding(
                          topPadding: topPadding,
                          bottomPadding: bottomPadding,
                          child: BondingCurveHolderTile(
                            holder: holder,
                          ),
                        );
                      }

                      if (holder.isBurning) {
                        return _HoldersListPadding(
                          topPadding: topPadding,
                          bottomPadding: bottomPadding,
                          child: BurningHolderTile(holder: holder),
                        );
                      }

                      return _HoldersListPadding(
                        topPadding: topPadding,
                        bottomPadding: bottomPadding,
                        child: TopHolderTile(
                          holder: holder,
                        ),
                      );
                    },
                  ),
                if (isLoadingMore.value)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsetsDirectional.all(10.0.s),
                        child: const IONLoadingIndicatorThemed(),
                      ),
                    ),
                  ),
              ],
              onLoadMore: () async {
                if (topHoldersAsync.isLoading) return;
                if (isLoadingMore.value || !hasMore.value) return;

                isLoadingMore.value = true;
                try {
                  hasMore.value = await ref.read(topHoldersProvider.notifier).loadMore();
                } finally {
                  isLoadingMore.value = false;
                }
              },
              hasMore: hasMore.value,
              builder: (context, slivers) {
                return PullToRefreshBuilder(
                  slivers: slivers,
                  onRefresh: () async {
                    hasMore.value = true;
                    ref.invalidate(topHoldersProvider);
                  },
                  builder: (context, slivers) => CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: scrollController,
                    slivers: slivers,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldersListPadding extends StatelessWidget {
  const _HoldersListPadding({
    required this.topPadding,
    required this.bottomPadding,
    required this.child,
  });

  final double topPadding;
  final double bottomPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: topPadding,
        bottom: bottomPadding,
        start: 16.s,
        end: 16.s,
      ),
      child: child,
    );
  }
}
