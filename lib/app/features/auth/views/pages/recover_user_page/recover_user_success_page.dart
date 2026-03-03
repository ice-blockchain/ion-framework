// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/card/warning_card.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class RecoverUserSuccessPage extends StatelessWidget {
  const RecoverUserSuccessPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    void onLogin() => GetStartedRoute().go(context);

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24.0.s),
          ScreenSideOffset.medium(
            child: InfoCard(
              iconAsset: Assets.svg.actionWalletSuccess2Fa,
              title: context.i18n.common_congratulations,
              description: context.i18n.two_fa_success_desc,
            ),
          ),
          SizedBox(height: 16.0.s),
          ScreenSideOffset.small(
            child: WarningCard(text: context.i18n.two_fa_success_warning_desc),
          ),
          SizedBox(height: 20.0.s),
          ScreenBottomOffset(
            child: ScreenSideOffset.small(
              child: Button(
                onPressed: onLogin,
                label: Text(context.i18n.button_log_in),
                mainAxisSize: MainAxisSize.max,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
