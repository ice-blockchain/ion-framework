// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenNotFoundDialog extends ConsumerWidget {
  const TokenNotFoundDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locales = context.i18n;
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(top: 8.0.s),
          child: NavigationAppBar.screen(
            showBackButton: false,
            actions: const [
              NavigationCloseButton(),
            ],
          ),
        ),
        ScreenSideOffset.small(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Assets.svg.walletIconWalletLoadingerror.icon(size: 80.0.s),
              SizedBox(height: 6.0.s),
              Text(
                locales.wallet_import_token_token_not_found_title,
                textAlign: TextAlign.center,
                style: textStyles.title.copyWith(color: colors.primaryText),
              ),
              SizedBox(height: 8.0.s),
              Text(
                locales.wallet_import_token_token_not_found_description,
                textAlign: TextAlign.center,
                style: textStyles.body2.copyWith(color: colors.secondaryText),
              ),
              SizedBox(height: 28.0.s),
              Button(
                label: Text(locales.button_try_again),
                onPressed: () => Navigator.pop(context),
              ),
              const ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }
}
