// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/manage_wallet_tile.dart';
import 'package:ion/app/features/wallets/views/components/wallets_list.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ManageWalletsModal extends ConsumerWidget {
  const ManageWalletsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletViews = ref.watch(walletViewsDataNotifierProvider).valueOrNull;

    final walletViewsCount = walletViews?.length ?? 0;
    final shouldShowCreateWalletButton = walletViewsCount < 2;

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.wallet_manage_wallets),
              actions: const [
                NavigationCloseButton(),
              ],
            ),
            SizedBox(height: shouldShowCreateWalletButton ? 17.0.s : 4.0.s),
            if (shouldShowCreateWalletButton)
              ScreenSideOffset.small(
                child: Button(
                  leadingIcon: Assets.svg.iconButtonAddstroke
                      .icon(color: context.theme.appColors.onPrimaryAccent),
                  onPressed: () {
                    CreateWalletRoute().push<void>(context);
                  },
                  label: Text(context.i18n.wallet_create_new),
                  mainAxisSize: MainAxisSize.max,
                ),
              ),
            ScreenSideOffset.small(
              child: WalletsList(
                padding: shouldShowCreateWalletButton ? null : EdgeInsets.zero,
                itemBuilder: (walletData) => ManageWalletTile(walletViewId: walletData.id),
              ),
            ),
            const ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
