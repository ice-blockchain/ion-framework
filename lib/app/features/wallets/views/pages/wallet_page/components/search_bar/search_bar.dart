// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/features/wallets/providers/filtered_assets_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/helpers/cancel_search_helper.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/search_visibility_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/tab_type.dart';

class WalletSearchBar extends ConsumerWidget {
  const WalletSearchBar({
    required this.tabType,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final WalletTabType tabType;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchVisibleProvider = walletSearchVisibilityProvider(tabType);
    final searchQueryProvider = walletSearchQueryControllerProvider(tabType.walletAssetType);

    final isSearchVisible = ref.watch(searchVisibleProvider);

    if (!isSearchVisible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: SearchInput(
        onTextChanged: (String newValue) {
          ref.read(searchQueryProvider.notifier).query = newValue;
        },
        onCancelSearch: () => cancelSearch(ref, tabType),
      ),
    );
  }
}
