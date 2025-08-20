// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/views/pages/manage_nfts/components/all_chains_item.dart';
import 'package:ion/app/features/wallets/views/pages/manage_nfts/components/manage_nft_item.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/view_models/nft_networks_view_model.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/collapsing_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ManageNftsPage extends HookConsumerWidget {
  const ManageNftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(nftNetworksViewModelProvider);

    useOnInit(() {
      viewModel.searchQueryCommand.execute('');
    });

    return SheetContent(
      body: Column(
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.wallet_manage_nfts),
            actions: [
              IconButton(
                icon: Assets.svg.iconSheetClose.icon(
                  size: NavigationAppBar.actionButtonSide,
                  color: context.theme.appColors.tertiaryText,
                ),
                onPressed: context.pop,
              ),
            ],
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                CollapsingAppBar(
                  height: SearchInput.height,
                  child: ScreenSideOffset.small(
                    child: SearchInput(
                      onTextChanged: viewModel.searchQueryCommand.execute,
                    ),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: viewModel.filteredNetworks,
                  builder: (context, filteredNetworks, _) {
                    if (filteredNetworks.isEmpty) {
                      return const NothingIsFound();
                    }

                    return SliverPadding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: ScreenBottomOffset.defaultMargin,
                      ),
                      sliver: SliverList.separated(
                        itemCount: filteredNetworks.length + 1,
                        separatorBuilder: (_, __) => SizedBox(height: 12.0.s),
                        itemBuilder: (context, index) => ScreenSideOffset.small(
                          child: index == 0
                              ? const AllChainsItem()
                              : ManageNftNetworkItem(
                                  network: filteredNetworks.elementAt(index - 1),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
