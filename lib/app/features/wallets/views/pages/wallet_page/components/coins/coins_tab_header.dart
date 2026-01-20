// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/search_bar/search_bar.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';

class CoinsTabHeader extends StatelessWidget {
  const CoinsTabHeader({
    required this.tabType,
    super.key,
  });

  final WalletTabType tabType;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ScreenSideOffset.small(
        child: WalletSearchBar(
          padding: EdgeInsetsDirectional.only(
            top: 8.0.s,
            bottom: 16.0.s,
          ),
          tabType: tabType,
        ),
      ),
    );
  }
}
