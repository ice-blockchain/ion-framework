// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class AboutImportTokenDialog extends ConsumerWidget {
  const AboutImportTokenDialog({
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
            title: Text(locales.common_information),
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
              Assets.svg.walleticonprofilewarningaddcoin.icon(size: 80.0.s),
              SizedBox(height: 6.0.s),
              Text(
                locales.wallet_import_token_about_title,
                textAlign: TextAlign.center,
                style: textStyles.title.copyWith(color: colors.primaryText),
              ),
              SizedBox(height: 8.0.s),
              Text(
                [
                  locales.wallet_import_token_about_description_1,
                  locales.wallet_import_token_about_description_2,
                  locales.wallet_import_token_about_description_3,
                ].join('\n\n'),
                textAlign: TextAlign.center,
                style: textStyles.body2.copyWith(color: colors.secondaryText),
              ),
              const ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }
}
