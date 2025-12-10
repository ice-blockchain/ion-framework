// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/filtered_assets_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/coins_list_view.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SelectCoinModalPage extends ConsumerWidget {
  const SelectCoinModalPage({
    required this.title,
    required this.onCoinSelected,
    this.showBackButton = false,
    this.showCloseButton = true,
    this.contactPubkey,
    this.coinsProvider,
    this.onQueryChanged,
    super.key,
  });

  final String title;
  final ValueChanged<CoinsGroup> onCoinSelected;
  final bool showBackButton;
  final bool showCloseButton;
  final String? contactPubkey;
  final ProviderListenable<AsyncValue<List<CoinsGroup>>>? coinsProvider;
  final void Function(String query)? onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectableCoinsResult =
        ref.watch(selectableFilteredCoinsProvider(contactPubkey: contactPubkey));
    final coinsResult = coinsProvider != null
        ? ref.watch(coinsProvider!)
        : selectableCoinsResult.whenData((state) => state.groups);
    final enabledSymbolGroups = selectableCoinsResult.valueOrNull?.enabledSymbolGroups;

    return SheetContent(
      body: CoinsListView(
        showBackButton: showBackButton,
        showCloseButton: showCloseButton,
        coinsResult: coinsResult,
        itemWrapperBuilder: (context, group, child) {
          final isEnabled =
              enabledSymbolGroups == null || enabledSymbolGroups.contains(group.symbolGroup);
          if (isEnabled) {
            return child;
          }
          return IgnorePointer(
            child: Opacity(
              opacity: 0.3,
              child: child,
            ),
          );
        },
        onItemTap: onCoinSelected,
        title: title,
        onQueryChanged: (String query) {
          if (onQueryChanged != null) {
            onQueryChanged!(query);
            return;
          }
          ref.read(filteredCoinsNotifierProvider.notifier).search(query);
        },
      ),
    );
  }
}
