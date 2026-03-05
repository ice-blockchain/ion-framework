// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/share_address/receive_info_card.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/components/info_card.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:ion/generated/assets.gen.dart';

class ShareAddressSheetContent extends StatelessWidget {
  const ShareAddressSheetContent({
    required this.coin,
    required this.network,
    required this.walletAddress,
    super.key,
  });

  final CoinsGroup? coin;
  final NetworkData network;
  final String? walletAddress;

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.s),
            child: NavigationAppBar.screen(
              title: Text(context.i18n.wallet_share_address),
              actions: [
                NavigationCloseButton(
                  onPressed: Navigator.of(context, rootNavigator: true).pop,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.s),
            child: Column(
              children: [
                ReceiveInfoCard(
                  network: network,
                  coinsGroup: coin,
                  walletAddress: walletAddress,
                ),
                SizedBox(
                  height: 16.0.s,
                ),
                const InfoCard(),
                SizedBox(
                  height: 16.0.s,
                ),
                Button.compact(
                  mainAxisSize: MainAxisSize.max,
                  minimumSize: Size(56.0.s, 56.0.s),
                  leadingIcon: Assets.svg.iconButtonShare
                      .icon(color: context.theme.appColors.secondaryBackground),
                  label: Text(
                    context.i18n.button_share,
                  ),
                  disabled: walletAddress == null,
                  onPressed: () {
                    if (walletAddress != null) {
                      shareContent(walletAddress!);
                    }
                  },
                ),
              ],
            ),
          ),
          const ScreenBottomOffset(),
        ],
      ),
    );
  }
}
