// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_main_modal/wallet_main_modal_list_item.dart';
import 'package:ion/app/hooks/use_on_receive_funds_flow.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/main_modal_item.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class WalletMainModalPage extends HookConsumerWidget {
  const WalletMainModalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onFlow = useCallback(
      (WalletMainModalListItem type) {
        ref.invalidate(sendAssetFormControllerProvider);
        context.pushReplacement(_getSubRouteLocation(type));
      },
      [],
    );
    final onReceiveFlow = useOnReceiveFundsFlow(
      onReceive: () => onFlow(WalletMainModalListItem.receive),
      onNeedToEnable2FA: () {
        context.pushReplacement(SecureAccountModalRoute().location);
      },
      ref: ref,
    );

    return SheetContent(
      topPadding: 0.0.s,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.wallet_modal_title),
              showBackButton: false,
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const HorizontalSeparator(),
              itemCount: WalletMainModalListItem.values.length,
              itemBuilder: (BuildContext context, int index) {
                final type = WalletMainModalListItem.values[index];

                return MainModalItem(
                  item: type,
                  onTap: () {
                    if (type == WalletMainModalListItem.receive) {
                      onReceiveFlow();
                    } else {
                      onFlow(type);
                    }
                  },
                  index: index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getSubRouteLocation(WalletMainModalListItem type) {
    return switch (type) {
      WalletMainModalListItem.send => SelectCoinWalletRoute().location,
      WalletMainModalListItem.receive => ReceiveCoinRoute().location,
    };
  }
}
