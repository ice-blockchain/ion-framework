// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
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
    final onReceiveFlow = useOnReceiveFundsFlow(
      onReceive: () => _onFlow(context, ref, WalletMainModalListItem.receive),
      onNeedToEnable2FA: () => context.pushReplacement(SecureAccountModalRoute().location),
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
                  item: type,
                  onTap: () {
                    if (type == WalletMainModalListItem.receive) {
                      onReceiveFlow();
                    } else {
                      _onFlow(context, ref, type);
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

  void _onFlow(
    BuildContext context,
    WidgetRef ref,
    WalletMainModalListItem type,
  ) {
    if (type == WalletMainModalListItem.swap) {
      return ref.read(messageNotificationNotifierProvider.notifier).show(
            MessageNotification(
              message: context.i18n.wallet_swap_coming_soon,
              icon: Assets.svg.iconBlockTime.icon(size: 16.0.s),
            ),
          );
    }

    final skipSelectCoinRoute = type == WalletMainModalListItem.send &&
        ref.read(sendAssetFormControllerProvider).assetData is CoinAssetToSendData;
    context.pushReplacement(
      _getSubRouteLocation(type, skipSelectCoinRoute: skipSelectCoinRoute),
    );
  }

  String _getSubRouteLocation(WalletMainModalListItem type, {bool skipSelectCoinRoute = false}) {
    return switch (type) {
      WalletMainModalListItem.send => skipSelectCoinRoute
          ? SelectNetworkWalletRoute().location
          : SelectCoinWalletRoute().location,
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
