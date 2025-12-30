// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/carousel/wallet_carousel.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_tokens_button.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/friends_section_providers.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/providers/manage_coins_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/balance/balance.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/coins/coins_tab.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/coins/coins_tab_header.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/friends/friends_list.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/header/wallet_header.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/nfts/nfts_tab.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/nfts/nfts_tab_header.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/tabs/tabs_header.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/components/navigation_app_bar/collapsing_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/utils/precache_pictures.dart';

class WalletPage extends HookConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    useScrollTopOnTabPress(context, scrollController: scrollController);

    final activeTab = useState<WalletTabType>(WalletTabType.coins);

    // Precache tier 1 network icons when wallet page opens
    useEffect(
      () {
        ref.read(networksByTierProvider(tier: 1).future).then((networks) {
          final iconUrls =
              networks.map((network) => network.image).where((url) => url.isNotEmpty).toList();
          if (iconUrls.isNotEmpty && context.mounted) {
            precachePictures(context, iconUrls);
          }
        });
        return null;
      },
      [],
    );

    final tokenizedCommunitiesEnabled = ref
        .watch(featureFlagsProvider.notifier)
        .get(TokenizedCommunitiesFeatureFlag.tokenizedCommunitiesEnabled);

    final showFriendsSection = ref.watch(shouldShowFriendsListProvider);

    return Scaffold(
      appBar: NavigationAppBar.root(
        title: const WalletHeader(),
        horizontalPadding: ScreenSideOffset.defaultSmallMargin,
        scrollController: scrollController,
        actions: [
          const ScanButton(),
          if (tokenizedCommunitiesEnabled) ...[
            SizedBox(width: 8.s),
            const CommunityTokensButton(),
          ],
        ],
      ),
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: PullToRefreshBuilder(
          sliverAppBar: CollapsingAppBar(
            height: Balance.height,
            bottomOffset: 0,
            child: Balance(tab: activeTab.value),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionSeparator(),
                  const WalletCarousel(),
                  if (showFriendsSection) ...[
                    const SectionSeparator(),
                    const FriendsList(),
                  ],
                  const SectionSeparator(),
                  WalletTabsHeader(
                    activeTab: activeTab.value,
                    onTabSwitch: (WalletTabType newTab) {
                      if (newTab != activeTab.value) {
                        activeTab.value = newTab;
                      }
                    },
                  ),
                ],
              ),
            ),
            ...switch (activeTab.value) {
              WalletTabType.coins => const [
                  CoinsTabHeader(tabType: WalletTabType.coins),
                  CoinsTab(tabType: WalletTabType.coins),
                ],
              WalletTabType.nfts => const [
                  SliverToBoxAdapter(
                    child: NftsTabHeader(),
                  ),
                  NftsTab(),
                ],
              WalletTabType.creatorTokens => const [
                  CoinsTabHeader(tabType: WalletTabType.creatorTokens),
                  CoinsTab(tabType: WalletTabType.creatorTokens),
                ],
            },
          ],
          onRefresh: () async {
            final currentUserFollowList = ref.read(currentUserFollowListProvider).valueOrNull;
            if (currentUserFollowList != null) {
              ref.read(ionConnectCacheProvider.notifier).remove(currentUserFollowList.cacheKey);
            }

            await ref
                .read(syncTransactionsServiceProvider.future)
                .then((service) => service.syncAll());

            ref
              ..invalidate(walletViewsDataNotifierProvider)
              ..invalidate(manageCoinsNotifierProvider);

            await ref.read(syncedCoinsBySymbolGroupNotifierProvider.notifier).refresh();
          },
          builder: (context, slivers) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            slivers: slivers,
          ),
        ),
      ),
    );
  }
}
