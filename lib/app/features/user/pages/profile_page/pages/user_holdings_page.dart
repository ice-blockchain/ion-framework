// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/top_holders/components/top_holders_skeleton.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/user_holdings_list_item.dart';
import 'package:ion/app/features/user/providers/user_holdings_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class UserHoldingsPage extends HookConsumerWidget {
  const UserHoldingsPage({required this.holderAddress, super.key});

  final String holderAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final isLoadingMore = useState(false);
    final hasMore = useState(true);
    final offset = useState(0);
    final accumulatedHoldings = useState<List<CommunityToken>>([]);

    final holdingsAsync = ref.watch(userHoldingsProvider(holderAddress, limit: 20));

    useEffect(
      () {
        final data = holdingsAsync.valueOrNull;
        if (data != null && offset.value == 0) {
          accumulatedHoldings.value = data.items;
          hasMore.value = data.hasMore;
        }
        return null;
      },
      [holdingsAsync],
    );

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(context.i18n.profile_holdings, style: context.theme.appTextThemes.subtitle2),
      ),
      body: Column(
        children: [
          const SimpleSeparator(),
          Expanded(
            child: LoadMoreBuilder(
              showIndicator: false,
              slivers: [
                if (holdingsAsync.isLoading && accumulatedHoldings.value.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 16.s, vertical: 12.s),
                      child: TopHoldersSkeleton(count: 20, seperatorHeight: 14.s),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: accumulatedHoldings.value.length,
                    itemBuilder: (context, index) {
                      final topPadding = index == 0 ? 12.s : 7.s;
                      final isLast = index == accumulatedHoldings.value.length - 1;
                      final bottomPadding = isLast ? 32.s : 7.s;

                      final padding = EdgeInsetsDirectional.only(
                        top: topPadding,
                        bottom: bottomPadding,
                        start: 16.s,
                        end: 16.s,
                      );

                      return UserHoldingsListItem(
                          token: accumulatedHoldings.value[index], padding: padding);
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
                if (holdingsAsync.isLoading) return;
                if (isLoadingMore.value || !hasMore.value) return;

                isLoadingMore.value = true;
                try {
                  final newOffset = offset.value + 20;
                  final result = await ref.read(
                    userHoldingsProvider(holderAddress, limit: 20, offset: newOffset).future,
                  );
                  accumulatedHoldings.value = [
                    ...accumulatedHoldings.value,
                    ...result.items,
                  ];
                  offset.value = newOffset;
                  hasMore.value = result.hasMore;
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
                    offset.value = 0;
                    accumulatedHoldings.value = [];
                    ref.invalidate(userHoldingsProvider(holderAddress, limit: 20));
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
