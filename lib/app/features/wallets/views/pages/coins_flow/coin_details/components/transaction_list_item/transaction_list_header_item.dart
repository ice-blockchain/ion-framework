// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_selector_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/constants.dart';

class TransactionListHeaderItem extends StatelessWidget {
  const TransactionListHeaderItem({
    required this.item,
    required this.onPress,
    required this.isSelected,
    super.key,
  });

  final bool isSelected;
  final VoidCallback onPress;
  final SelectedNetworkItem item;

  Color _getBorderColor(BuildContext context) {
    return isSelected
        ? context.theme.appColors.primaryAccent
        : context.theme.appColors.onTertiaryFill;
  }

  Color _getTextColor(BuildContext context) {
    return isSelected
        ? context.theme.appColors.primaryText
        : context.theme.appColors.onTertiaryBackground;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8.0.s);
    return Material(
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onPress,
        borderRadius: borderRadius,
        child: Ink(
          height: TransactionListConstants.headerItemHeight,
          decoration: BoxDecoration(
            color: context.theme.appColors.tertiaryBackground,
            borderRadius: borderRadius,
            border: Border.all(
              color: _getBorderColor(context),
              width: 1.0.s,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 5.0.s,
          ),
          child: Row(
            children: [
              item.when(
                network: (network) => NetworkIconWidget(
                  type: WalletItemIconType.small(),
                  imageUrl: network.image,
                ),
                all: (_) => item.image.icon(size: 16.0.s),
              ),
              SizedBox(
                width: 6.0.s,
              ),
              Text(
                item.getDisplayName(context),
                style: context.theme.appTextThemes.body2.copyWith(
                  color: _getTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
