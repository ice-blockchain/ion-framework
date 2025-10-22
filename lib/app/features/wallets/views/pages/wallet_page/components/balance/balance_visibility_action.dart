// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/user_preferences_selectors.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_user_preferences/wallet_user_preferences_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class BalanceVisibilityAction extends ConsumerWidget {
  const BalanceVisibilityAction({
    required this.hitSlop,
    this.isLoading = false,
    super.key,
  });

  final double hitSlop;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceVisible = ref.watch(isBalanceVisibleSelectorProvider);
    final iconAsset = isBalanceVisible ? Assets.svg.iconBlockEyeOn : Assets.svg.iconBlockEyeOff;

    if (isLoading) {
      return ContainerSkeleton(
        width: 84.0.s,
        height: 16.0.s,
        margin: EdgeInsets.symmetric(vertical: 9.0.s),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.i18n.wallet_balance,
          style: context.theme.appTextThemes.subtitle2
              .copyWith(color: context.theme.appColors.secondaryText),
        ),
        TextButton(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hitSlop),
            child: iconAsset.icon(
              color: context.theme.appColors.secondaryText,
            ),
          ),
          onPressed: () {
            final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider) ?? '';
            ref
                .read(
                  walletUserPreferencesNotifierProvider(identityKeyName: identityKeyName).notifier,
                )
                .switchBalanceVisibility();
          },
        ),
      ],
    );
  }
}
