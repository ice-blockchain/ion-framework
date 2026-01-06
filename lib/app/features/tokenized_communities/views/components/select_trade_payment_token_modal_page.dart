// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/coins_list_view.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SelectTradePaymentTokenModalPage extends ConsumerWidget {
  const SelectTradePaymentTokenModalPage({
    required this.title,
    this.showBackButton = true,
    this.showCloseButton = false,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsResult = ref.watch(supportedSwapTokenGroupsProvider);

    return SheetContent(
      body: KeyboardDismissOnTap(
        child: CoinsListView(
          showBackButton: showBackButton,
          showCloseButton: showCloseButton,
          coinsResult: coinsResult,
          onItemTap: (group) {
            if (group.coins.isEmpty) return;
            Navigator.of(context).pop(group.coins.first.coin);
          },
          title: title,
        ),
      ),
    );
  }
}
