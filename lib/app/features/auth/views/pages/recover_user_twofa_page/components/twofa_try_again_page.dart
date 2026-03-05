// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/generated/assets.gen.dart';

class TwoFaTryAgainPage extends StatelessWidget {
  const TwoFaTryAgainPage({
    this.description,
    super.key,
  });

  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.0.s),
          child: Column(
            children: [
              InfoCard(
                iconAsset: Assets.svg.actionWalletKeyserror,
                title: context.i18n.two_fa_failure_title,
                description: description ?? context.i18n.two_fa_failure_desc,
              ),
            ],
          ),
        ),
        SizedBox(height: 30.0.s),
        ScreenSideOffset.small(
          child: Button(
            onPressed: () => rootNavigatorKey.currentState?.pop(),
            label: Text(context.i18n.button_try_again),
            mainAxisSize: MainAxisSize.max,
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
