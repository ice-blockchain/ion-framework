// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/select/select_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/generated/assets.gen.dart';

class SelectNetworkButton extends StatelessWidget {
  const SelectNetworkButton({
    required this.onTap,
    required this.selectedNetwork,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onTap;
  final NetworkData? selectedNetwork;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: selectedNetwork == null
          ? const _NoNetworkSelected()
          : _HasNetworkSelected(
              selectedNetwork: selectedNetwork!,
              enabled: enabled,
            ),
    );
  }
}

class _NoNetworkSelected extends StatelessWidget {
  const _NoNetworkSelected();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    return SelectContainer(
      child: Row(
        children: [
          Assets.svg.walletnetwork.icon(size: 30.0.s),
          SizedBox(width: 10.0.s),
          Text(
            context.i18n.common_select_network_button_unselected,
            style: textTheme.body.copyWith(
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _HasNetworkSelected extends StatelessWidget {
  const _HasNetworkSelected({
    required this.selectedNetwork,
    required this.enabled,
  });

  final NetworkData selectedNetwork;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    return SelectContainer(
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            context.i18n.wallet_network,
            style: textTheme.caption3.copyWith(
              color: colors.secondaryText,
            ),
          ),
          SizedBox(height: 2.0.s),
          Row(
            children: [
              NetworkIconWidget(
                type: WalletItemIconType.small(),
                imageUrl: selectedNetwork.image,
              ),
              SizedBox(width: 10.0.s),
              Expanded(
                child: Text(
                  selectedNetwork.displayName,
                  style: textTheme.body,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0.s),
          const Spacer(),
        ],
      ),
    );
  }
}
