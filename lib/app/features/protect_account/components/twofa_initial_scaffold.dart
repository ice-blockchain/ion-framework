// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/rounded_card.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class TwoFaInitialScaffold extends StatelessWidget {
  const TwoFaInitialScaffold({
    required this.headerIcon,
    required this.headerTitle,
    required this.prompt,
    required this.buttonLabel,
    required this.onButtonPressed,
    super.key,
  });

  final Widget headerIcon;
  final String headerTitle;
  final Widget prompt;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return SheetContent(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationAppBar.modal(),
          AuthHeader(
            title: headerTitle,
            titleStyle: context.theme.appTextThemes.headline2,
            descriptionStyle: context.theme.appTextThemes.body2.copyWith(
              color: colors.secondaryText,
            ),
            icon: headerIcon,
          ),
          const Spacer(),
          ScreenSideOffset.large(
            child: RoundedCard.filled(
              padding: EdgeInsets.symmetric(
                vertical: 56.0.s,
                horizontal: 12.0.s,
              ),
              child: prompt,
            ),
          ),
          const Spacer(),
          ScreenSideOffset.large(
            child: Button(
              type: ButtonType.outlined,
              mainAxisSize: MainAxisSize.max,
              label: Text(
                buttonLabel,
                style: context.theme.appTextThemes.body.copyWith(color: colors.secondaryText),
              ),
              onPressed: onButtonPressed,
            ),
          ),
          const ScreenBottomOffset(),
        ],
      ),
    );
  }
}
