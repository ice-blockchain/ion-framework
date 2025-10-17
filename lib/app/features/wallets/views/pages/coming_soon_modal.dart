// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ComingSoonModal extends StatelessWidget {
  const ComingSoonModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      topPadding: 12.s,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.coming_soon_label),
            actions: const [NavigationCloseButton()],
          ),
          Assets.svg.iconBlockTime.icon(
            size: 64.s,
            color: context.theme.appColors.primaryAccent,
          ),
          SizedBox(height: 36.0.s),
          Text(
            context.i18n.coming_soon_description,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.0.s),
        ],
      ),
    );
  }
}
