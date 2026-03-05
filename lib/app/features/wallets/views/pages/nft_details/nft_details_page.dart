// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:ion/app/features/wallets/views/pages/nft_details/components/nft_details.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class NftDetailsPage extends ConsumerWidget {
  const NftDetailsPage({
    required this.contract,
    required this.tokenId,
    super.key,
  });

  final String contract;
  final String tokenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: SingleChildScrollView(
        restorationId: 'wallet_nft_details_page_scroll',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.send_nft_navigation_title),
              showBackButton: false,
              actions: const [NavigationCloseButton()],
            ),
            ScreenSideOffset.small(
              child: SingleChildScrollView(
                restorationId: 'wallet_nft_details_inner_scroll',
                padding: EdgeInsetsDirectional.only(top: 10.0.s),
                child: NftDetails(
                  nftIdentifier: NftIdentifier(contract: contract, tokenId: tokenId),
                ),
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
