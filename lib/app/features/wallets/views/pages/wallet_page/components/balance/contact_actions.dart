// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/hooks/use_on_receive_funds_flow.dart';
import 'package:ion/generated/assets.gen.dart';

class ContactActions extends HookConsumerWidget {
  const ContactActions({
    required this.onReceive,
    required this.onSend,
    required this.onNeedToEnable2FA,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onReceive;
  final VoidCallback onSend;
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
          child: Button.compact(
            leadingIcon: Assets.svg.iconButtonSend.icon(),
            label: Text(
              context.i18n.wallet_send,
            ),
            onPressed: isLoading ? () {} : onSend,
          ),
        ),
        SizedBox(
          width: 12.0.s,
        ),
        Expanded(
          child: Button.compact(
            type: isLoading ? ButtonType.primary : ButtonType.outlined,
            leadingIcon: Assets.svg.iconButtonReceive.icon(),
            label: Text(
              context.i18n.wallet_receive,
            ),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(context.theme.appColors.tertiaryBackground),
              side: WidgetStateProperty.all(
                BorderSide(
                  color: context.theme.appColors.onTertiaryFill,
                  width: 1.0.s,
                ),
              ),
            ),
            onPressed: isLoading ? () {} : onReceiveFlow,
          ),
        ),
      ],
    );

    return isLoading ? Skeleton(child: child) : child;
  }
}
