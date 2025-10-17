// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/nft_details/hooks/use_show_tooltip_overlay.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_main_modal/wallet_main_modal_list_item.dart';
import 'package:ion/app/hooks/use_on_receive_funds_flow.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/main_modal_item.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletMainModalPage extends HookConsumerWidget {
  const WalletMainModalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapButtonKey = useRef(GlobalKey());
    final showSwapTooltipOverlay = useShowTooltipOverlay(
      targetKey: swapButtonKey.value,
      text: context.i18n.wallet_swap_coming_soon,
    );
    final onFlow = useCallback(
      (WalletMainModalListItem type) {
        if (type == WalletMainModalListItem.swap) {
          return showSwapTooltipOverlay();
        }
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
            const _Header(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const HorizontalSeparator(),
              itemCount: WalletMainModalListItem.values.length,
              itemBuilder: (BuildContext context, int index) {
                final type = WalletMainModalListItem.values[index];

                return MainModalItem(
                  key: type == WalletMainModalListItem.swap ? swapButtonKey.value : null,
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
      WalletMainModalListItem.swap => '', // TODO: add swap route when the feature is implemented
    };
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBuySellButtons = ref
        .read(featureFlagsProvider.notifier)
        .get(TokenizedCommunitiesFeatureFlag.tokenizedCommunitiesEnabled);

    if (!showBuySellButtons) {
      return NavigationAppBar.modal(
        title: Text(context.i18n.wallet_modal_title),
        showBackButton: false,
      );
    }

    return Column(
      children: [
        SizedBox(height: 24.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0.s),
          child: Row(
            children: [
              Expanded(
                child: Button.compact(
                  leadingIconOffset: 4.s,
                  leadingIcon: Assets.svg.iconWalletBuy.icon(),
                  label: Text(context.i18n.wallet_buy),
                  // TODO: implement buy currency flow
                  onPressed: () {},
                ),
              ),
              SizedBox(width: 12.0.s),
              Expanded(
                child: Button.compact(
                  leadingIconOffset: 4.s,
                  leadingIcon: Assets.svg.iconMemeCoins.icon(),
                  label: Text(context.i18n.wallet_sell),
                  // TODO: implement sell currency flow
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.s),
        const HorizontalSeparator(),
        SizedBox(height: 8.s),
      ],
    );
  }
}
