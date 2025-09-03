// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
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
          if (iconUrls.isNotEmpty) {
            precachePictures(iconUrls);
          }
        });
        return null;
      },
      [],
    );

    return Scaffold(
      appBar: NavigationAppBar.root(
        title: const WalletHeader(),
        horizontalPadding: ScreenSideOffset.defaultSmallMargin,
        scrollController: scrollController,
        actions: const [
          ScanButton(),
        ],
      ),
      body: PullToRefreshBuilder(
        sliverAppBar: CollapsingAppBar(
          height: Balance.height,
          bottomOffset: 0,
          child: Balance(tab: activeTab.value),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const FriendsList(),
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
                CoinsTabHeader(),
                CoinsTab(),
              ],
            WalletTabType.nfts => const [
                SliverToBoxAdapter(
                  child: NftsTabHeader(),
                ),
                NftsTab(),
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
    );
  }
}
