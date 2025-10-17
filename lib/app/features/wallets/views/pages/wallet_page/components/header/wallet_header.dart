// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/components/wallet_switcher/wallet_switcher.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_button/navigation_button.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletHeader extends ConsumerWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dappsEnabled =
        ref.watch(featureFlagsProvider.notifier).get(WalletFeatureFlag.dappsEnabled);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SizedBox(
        height: NavigationButton.defaultSize,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: WalletSwitcher(),
              ),
            ),
            if (dappsEnabled) ...[
              SizedBox(width: 12.0.s),
              NavigationButton(
                onPressed: () => DAppsRoute().push<void>(context),
                icon: Assets.svg.iconDappOff.icon(
                  color: context.theme.appColors.primaryText,
                ),
              ),
            ],
            SizedBox(width: 12.0.s),
          ],
        ),
      ),
    );
  }
}

class ScanButton extends ConsumerWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationButton(
      onPressed: () => _onScanPressed(ref),
      icon: Assets.svg.iconHeaderScan1.icon(
        color: context.theme.appColors.primaryText,
      ),
    );
  }

  Future<void> _onScanPressed(WidgetRef ref) async {
    final scannedAddress = await ScanWalletRoute().push<String>(ref.context);
    if (scannedAddress == null || !ref.context.mounted) return;

    // Navigation to the CoinSendRoute doesn't work while the bottom sheet animation is running
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!ref.context.mounted) return; // Check again after delay

    ref.invalidate(sendAssetFormControllerProvider);
    ref.read(sendAssetFormControllerProvider.notifier).setReceiverAddress(scannedAddress);
    await SendCoinsFormWalletRoute().push<void>(ref.context);
  }
}

class CardButton extends StatelessWidget {
  const CardButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationButton(
      onPressed: () {},
      icon: Assets.svg.walletIconCard.icon(
        color: context.theme.appColors.primaryAccent,
      ),
    );
  }
}
