// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/views/components/coins_list/coin_item.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class CoinsListView extends StatelessWidget {
  const CoinsListView({
    required this.onItemTap,
    required this.title,
    required this.coinsResult,
    required this.onQueryChanged,
    this.showBackButton = false,
    this.showCloseButton = true,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final bool showCloseButton;
  final AsyncValue<List<CoinsGroup>> coinsResult;
  final void Function(CoinsGroup group) onItemTap;
  final void Function(String query) onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0.s),
          child: NavigationAppBar.screen(
            title: Text(title),
            showBackButton: showBackButton,
            actions: [
              if (showCloseButton) const NavigationCloseButton(),
            ],
          ),
        ),
        ScreenSideOffset.small(
          child: SearchInput(
            onTextChanged: onQueryChanged,
            hintText: context.i18n.wallet_coins_search_hint,
          ),
        ),
        SizedBox(
          height: 12.0.s,
        ),
        Expanded(
          child: coinsResult.maybeWhen(
            data: (groups) {
              if (groups.isEmpty) {
                return const _EmptyState();
              }

              return ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 12.0.s,
                  );
                },
                itemBuilder: (BuildContext context, int index) {
                  return ScreenSideOffset.small(
                    child: CoinsGroupItem(
                      coinsGroup: groups[index],
                      onTap: () => onItemTap(groups[index]),
                    ),
                  );
                },
              );
            },
            orElse: () => ListItemsLoadingState(
              itemsCount: 11,
              itemHeight: 60.0.s,
              listItemsLoadingStateType: ListItemsLoadingStateType.listView,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Assets.svg.walletIconWalletEmptysearch.icon(size: 48.0.s),
        SizedBox(height: 8.0.s),
        Text(
          context.i18n.core_empty_search,
          style: textStyles.caption2.copyWith(color: colors.tertiaryText),
        ),
      ],
    );
  }
}
