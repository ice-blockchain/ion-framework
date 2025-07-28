// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/wallet_icon.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class WalletSwitcher extends ConsumerWidget {
  const WalletSwitcher({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletData = ref.watch(currentWalletViewDataProvider).valueOrNull;

    if (walletData == null) {
      return Skeleton(
        child: _WalletSwitcherButton(title: 'main', onPressed: () {}, key: key),
      );
    }
    return _WalletSwitcherButton(
      title: walletData.name,
      onPressed: () {
        WalletsRoute().push<void>(context);
      },
      key: key,
    );
  }
}

class _WalletSwitcherButton extends StatelessWidget {
  const _WalletSwitcherButton({
    required this.title,
    required this.onPressed,
    super.key,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Button.dropdown(
      onPressed: onPressed,
      leadingIcon: const WalletIcon(
        size: 28,
        iconSize: 18.6,
        borderRadius: 8,
      ),
      // leadingIconOffset: 6.0.s,
      // trailingIconOffset: 6.0.s,
      backgroundColor: context.theme.appColors.tertiaryBackground,
      label: Text(
        title,
        style: context.theme.appTextThemes.subtitle2.copyWith(
          color: context.theme.appColors.primaryText,
        ),
      ),
    );
  }
}
