// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/wallets/views/components/wallet_tile.dart';
import 'package:ion/app/features/wallets/views/components/wallets_list.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletsModal extends StatelessWidget {
  const WalletsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      body: SingleChildScrollView(
        restorationId: 'wallet_wallets_modal_scroll',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.wallet_wallets),
              showBackButton: false,
              actions: const [
                NavigationCloseButton(),
              ],
            ),
            ScreenSideOffset.small(
              child: WalletsList(
                itemBuilder: (walletData) => WalletTile(walletData: walletData),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: 16.0.s,
                top: 8.0.s,
                start: ScreenSideOffset.defaultSmallMargin,
                end: ScreenSideOffset.defaultSmallMargin,
              ),
              child: Button(
                leadingIcon: Assets.svg.iconButtonManageWallet.icon(),
                onPressed: () {
                  ManageWalletsRoute().push<void>(context);
                },
                label: Text(context.i18n.wallet_manage_wallets),
                mainAxisSize: MainAxisSize.max,
                type: ButtonType.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
