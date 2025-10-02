// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';

class NsfwBlockedSheet extends StatelessWidget {
  const NsfwBlockedSheet({super.key});

  @override
  Widget build(BuildContext context) {
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
            actions: const [NavigationCloseButton()],
          ),
        ),
        ScreenSideOffset.small(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 6.0.s),
              Text(
                locales.nsfw_blocked_dialog_title,
                textAlign: TextAlign.center,
                style: textStyles.title.copyWith(color: colors.primaryText),
              ),
              SizedBox(height: 8.0.s),
              Text(
                _getBodyText(context),
                textAlign: TextAlign.center,
                style: textStyles.body2.copyWith(color: colors.secondaryText),
              ),
              SizedBox(height: 28.0.s),
              Button(
                label: Text(locales.button_close),
                onPressed: () => Navigator.pop(context),
              ),
              ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }

  String _getBodyText(BuildContext context) {
    final locales = context.i18n;
    return switch (Platform.isIOS) {
      true => locales.nsfw_blocked_dialog_body_ios,
      false => locales.nsfw_blocked_dialog_body_android,
    };
  }
}

Future<void> showNsfwBlockedSheet(BuildContext context) {
  return showSimpleBottomSheet<void>(
    context: context,
    child: const NsfwBlockedSheet(),
  );
}
