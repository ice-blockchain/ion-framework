// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/constants/string.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/selected_wallet_view_id_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/wallet_icon.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletTile extends ConsumerWidget {
  const WalletTile({
    required this.walletData,
    super.key,
  });

  final WalletViewData walletData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWalletId = ref.watch(currentWalletViewIdProvider).valueOrNull;
    final isSelected = walletData.id == selectedWalletId;
    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: ListItem(
        isSelected: isSelected,
        onTap: () {
          if (!isSelected) {
            ref.read(selectedWalletViewIdNotifierProvider.notifier).selectedWalletId =
                walletData.id;
            Navigator.of(context).pop();
          }
        },
        leading: const WalletIcon(),
        title: Text(
          walletData.name,
        ),
        subtitle: Text(
          isBalanceVisible ? formatToCurrency(walletData.usdBalance) : StringConstants.obfuscated,
          style: context.theme.appTextThemes.caption3.copyWith(
            color: isSelected
                ? context.theme.appColors.onPrimaryAccent
                : context.theme.appColors.tertiaryText,
          ),
        ),
        trailing: isSelected == true ? Assets.svg.iconBlockCheckboxOn.icon() : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 11.0.s),
        backgroundColor: context.theme.appColors.tertiaryBackground,
      ),
    );
  }
}
