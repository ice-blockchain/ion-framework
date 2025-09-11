// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/modal_sheets/simple_modal_sheet.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class EntityLanguageWarningModal extends StatelessWidget {
  const EntityLanguageWarningModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleModalSheet.alert(
      title: context.i18n.common_select_language,
      description: context.i18n.select_language_warning,
      iconAsset: Assets.svg.actionWalletSelectlanguage,
      button: ScreenSideOffset.small(
        child: Button(
          mainAxisSize: MainAxisSize.max,
          label: Text(context.i18n.common_select_language),
          onPressed: () {
            EntityLanguageRoute().pushReplacement(context);
          },
        ),
      ),
      topOffset: 40.0.s,
    );
  }
}
