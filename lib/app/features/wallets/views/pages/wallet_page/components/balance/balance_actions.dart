// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/hooks/use_on_receive_funds_flow.dart';
import 'package:ion/generated/assets.gen.dart';

class BalanceActions extends HookConsumerWidget {
  const BalanceActions({
    required this.onReceive,
    required this.onNeedToEnable2FA,
    required this.onBuy,
    required this.onSwap,
    required this.onMore,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onReceive;
  final VoidCallback onBuy;
  final VoidCallback onSwap;
  final VoidCallback onMore;
  final bool isLoading;
  final void Function() onNeedToEnable2FA;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onReceiveFlow = useOnReceiveFundsFlow(
      onReceive: onReceive,
      onNeedToEnable2FA: onNeedToEnable2FA,
      ref: ref,
    );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextIconButton(
            icon: Assets.svg.iconWalletBuy.icon(),
            label: context.i18n.wallet_buy,
            onPressed: onBuy,
            disabled: isLoading,
          ),
        ),
        SizedBox(width: 12.0.s),
        Expanded(
          child: TextIconButton(
            icon: Assets.svg.iconButtonQrcode.icon(color: context.theme.appColors.primaryAccent),
            label: context.i18n.wallet_receive,
            onPressed: onReceiveFlow,
            type: ButtonType.outlined,
            disabled: isLoading,
          ),
        ),
        SizedBox(width: 12.0.s),
        Expanded(
          child: TextIconButton(
            icon: Assets.svg.iconamoonSwap.icon(color: context.theme.appColors.primaryAccent),
            label: context.i18n.wallet_swap,
            onPressed: onSwap,
            disabled: isLoading,
            type: ButtonType.outlined,
          ),
        ),
        SizedBox(width: 12.0.s),
        Expanded(
          child: TextIconButton(
            icon: Assets.svg.iconButtonMore.icon(color: context.theme.appColors.primaryAccent),
            label: context.i18n.wallet_more,
            onPressed: onMore,
            disabled: isLoading,
            type: ButtonType.outlined,
          ),
        ),
      ],
    );

    return isLoading ? Skeleton(child: child) : child;
  }
}
