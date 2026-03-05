// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/components/import_token_action_button.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/components/manage_coin_item_widget.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/providers/manage_coins_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class ManageCoinsPage extends HookConsumerWidget {
  const ManageCoinsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = useState('');
    final searchCoinsNotifier = ref.watch(searchCoinsNotifierProvider.notifier);
    final searchResult = ref.watch(searchCoinsNotifierProvider);
    final manageCoins = ref.watch(manageCoinsNotifierProvider);

    useEffect(
      () {
        final notifier = ref.read(manageCoinsNotifierProvider.notifier)..enableSave();
        return notifier.save;
      },
      [],
    );
    useOnInit(
      () => searchCoinsNotifier.search(query: searchText.value),
      [searchText.value],
    );

    return SheetContent(
      body: Column(
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.wallet_manage_coins),
            actions: const [
              ImportTokenActionButton(),
            ],
          ),
          Expanded(
            child: CustomScrollView(
              restorationId: 'wallet_manage_coins_page_scroll',
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: context.theme.appColors.onPrimaryAccent,
                  surfaceTintColor: context.theme.appColors.onPrimaryAccent,
                  toolbarHeight: SearchInput.height,
                  flexibleSpace: ScreenSideOffset.small(
                    child: SafeArea(
                      bottom: false,
                      child: SearchInput(
                        restorationId: 'manage_coins_search_input',
                        onTextChanged: (String value) => searchText.value = value,
                        loading: searchResult.isLoading,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 12.s)),
                if (searchText.value.isEmpty)
                  manageCoins.maybeWhen(
                    data: (coins) {
                      if (coins.isEmpty) return const NothingIsFound();
                      return _CoinsList(
                        itemCount: coins.length,
                        itemProvider: (index) => coins.values.elementAt(index).coinsGroup,
                      );
                    },
                    loading: () => const _ProgressIndicator(),
                    orElse: () => const NothingIsFound(),
                  )
                else
                  searchResult.maybeWhen(
                    data: (coins) {
                      if (coins.isEmpty) return const NothingIsFound();
                      return _CoinsList(
                        itemCount: coins.length,
                        itemProvider: (index) => coins.elementAt(index),
                      );
                    },
                    loading: () => const _ProgressIndicator(),
                    orElse: () => const NothingIsFound(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinsList extends StatelessWidget {
  const _CoinsList({required this.itemCount, required this.itemProvider});

  final int itemCount;
  final CoinsGroup Function(int index) itemProvider;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsetsDirectional.only(
        bottom: ScreenBottomOffset.defaultMargin,
      ),
      sliver: SliverList.separated(
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: 12.0.s),
        itemBuilder: (BuildContext context, int index) {
          return ScreenSideOffset.small(
            child: ManageCoinItemWidget(
              coinsGroup: itemProvider(index),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return ListItemsLoadingState(
      itemsCount: 7,
      separatorHeight: 12.0.s,
      listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
    );
  }
}
