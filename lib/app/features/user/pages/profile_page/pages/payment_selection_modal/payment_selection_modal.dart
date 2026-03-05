// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/payment_type.dart';
import 'package:ion/app/features/user/providers/request_coins_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/hooks/use_on_receive_funds_flow.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

typedef SelectCoinRouteLocationBuilder = String Function(PaymentType paymentType);

class PaymentSelectionModal extends HookConsumerWidget {
  const PaymentSelectionModal({
    required this.pubkey,
    required this.selectCoinRouteLocationBuilder,
    super.key,
  });

  final String pubkey;
  final SelectCoinRouteLocationBuilder selectCoinRouteLocationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onContinue = useCallback(
      (PaymentType paymentType) {
        switch (paymentType) {
          case PaymentType.send:
            ref.invalidate(sendAssetFormControllerProvider);
            ref.read(sendAssetFormControllerProvider.notifier).setContact(
                  pubkey,
                  isContactPreselected: true,
                );
          case PaymentType.request:
            ref.invalidate(requestCoinsFormControllerProvider);
            ref.read(requestCoinsFormControllerProvider.notifier).setContact(pubkey);
        }
        context.push(selectCoinRouteLocationBuilder(paymentType));
      },
      [],
    );
    final onRequestFlow = useOnReceiveFundsFlow(
      onReceive: () => onContinue(PaymentType.request),
      onNeedToEnable2FA: () => Navigator.of(context).pop(true),
      ref: ref,
    );

    return SheetContent(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.common_select_option),
            actions: [
              NavigationCloseButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(
            height: 8.0.s,
          ),
          for (final PaymentType option in PaymentType.values)
            ScreenSideOffset.small(
              child: Column(
                children: [
                  ListItem(
                    title: Text(option.getTitle(context)),
                    subtitle: Text(
                      option.getDesc(context),
                      maxLines: 2,
                    ),
                    backgroundColor: context.theme.appColors.tertiaryBackground,
                    leading: option.iconAsset.icon(size: 48.0.s),
                    onTap: () {
                      if (option == PaymentType.request) {
                        onRequestFlow();
                      } else {
                        onContinue(option);
                      }
                    },
                    trailing: Assets.svg.iconArrowRight.icon(
                      color: context.theme.appColors.primaryText,
                    ),
                  ),
                  SizedBox(
                    height: 16.0.s,
                  ),
                ],
              ),
            ),
          const ScreenBottomOffset(),
        ],
      ),
    );
  }
}
