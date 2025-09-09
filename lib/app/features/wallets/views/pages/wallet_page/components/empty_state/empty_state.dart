// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/empty_list/empty_list.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/providers/filtered_assets_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/bottom_action/bottom_action.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/search_visibility_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class EmptyState extends ConsumerWidget {
  const EmptyState({
    required this.tabType,
    required this.onBottomActionTap,
    super.key,
  });

  final WalletTabType tabType;
  final VoidCallback onBottomActionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(
      walletSearchQueryControllerProvider(tabType.walletAssetType),
    );
    final searchVisibleProvider = walletSearchVisibilityProvider(tabType);
    final isSearchVisible = ref.watch(searchVisibleProvider);

    final toShowNoResults = searchValue.isNotEmpty == true;

    final asset = toShowNoResults ? Assets.svg.walletIconWalletEmptysearch : tabType.emptyListAsset;
    final title =
        toShowNoResults ? context.i18n.core_empty_search : tabType.getEmptyListTitle(context);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: ScreenSideOffset.small(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: tabType == WalletTabType.nfts
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EmptyList(
                          asset: asset,
                          title: title,
                        ),
                        SizedBox(height: 8.s),
                        TextButton(
                          onPressed: () {
                            SelectNetworkToReceiveNftRoute().push<void>(ref.context);
                          },
                          child: Text(
                            context.i18n.wallet_receive_nft,
                            style: context.theme.appTextThemes.caption
                                .copyWith(color: context.theme.appColors.primaryAccent),
                          ),
                        ),
                      ],
                    )
                  : EmptyList(
                      asset: asset,
                      title: title,
                    ),
            ),
            if (!isSearchVisible && tabType != WalletTabType.nfts)
              BottomAction(
                asset: tabType.bottomActionAsset,
                title: tabType.getBottomActionTitle(context),
                onTap: onBottomActionTap,
              ),
          ],
        ),
      ),
    );
  }
}
