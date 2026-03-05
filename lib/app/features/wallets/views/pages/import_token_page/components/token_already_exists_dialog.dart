// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenAlreadyExistsDialog extends ConsumerWidget {
  const TokenAlreadyExistsDialog({
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
        NavigationAppBar.screen(
          showBackButton: false,
        ),
        ScreenSideOffset.small(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Assets.svg.walletIconProfileCoininwallet.icon(size: 80.0.s),
              SizedBox(height: 6.0.s),
              Text(
                locales.wallet_import_token_token_already_exists_title,
                textAlign: TextAlign.center,
                style: textStyles.title.copyWith(color: colors.primaryText),
              ),
              SizedBox(height: 8.0.s),
              Text(
                locales.wallet_import_token_token_already_exists_description,
                textAlign: TextAlign.center,
                style: textStyles.body2.copyWith(color: colors.secondaryText),
              ),
              SizedBox(height: 28.0.s),
              Button(
                label: Text(locales.button_close),
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
