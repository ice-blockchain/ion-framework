// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/wallets/providers/current_nfts_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/nfts/nfts_header_layout_action.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/nfts/nfts_header_select_action.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/search_bar/search_bar.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';

class NftsTabHeader extends HookConsumerWidget {
  const NftsTabHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNftsState = ref.watch(currentNftsProvider);
    final isLoading = currentNftsState.isLoading;

    if (isLoading) {
      return ScreenSideOffset.small(
        child: WalletSearchBar(
          padding: EdgeInsetsDirectional.only(top: UiConstants.hitSlop),
          tabType: WalletTabType.nfts,
        ),
      );
    }

    final padding = useMemoized(() => ScreenSideOffset.defaultSmallMargin - UiConstants.hitSlop);

    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: 16.0.s - UiConstants.hitSlop,
        start: padding,
        end: padding,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: NftHeaderSelectAction()),
              NftHeaderLayoutAction(),
            ],
          ),
          WalletSearchBar(
            padding: EdgeInsetsDirectional.only(
              start: UiConstants.hitSlop,
              end: UiConstants.hitSlop,
              top: 16.0.s - UiConstants.hitSlop,
              bottom: UiConstants.hitSlop,
            ),
            tabType: WalletTabType.nfts,
          ),
        ],
      ),
    );
  }
}
