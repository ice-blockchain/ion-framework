// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/checkbox/labeled_checkbox.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class DelegateAccessModal extends HookWidget {
  const DelegateAccessModal({super.key});

  @override
  Widget build(BuildContext context) {
    final isChecked = useState(false);

    void selectAndConfirmUser() {
      if (!context.mounted) return;
      SelectDelegateUserRoute().pushReplacement(context);
    }

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              onBackPress: () => context.pop(true),
              actions: const [NavigationCloseButton()],
            ),
            ScreenSideOffset.medium(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.svg.actionSettingsDelegate.icon(size: 80.0.s),
                  SizedBox(height: 8.0.s),
                  Text(
                    context.i18n.settings_delegate_access,
                    style: context.theme.appTextThemes.title,
                  ),
                  SizedBox(height: 12.0.s),
                  Text(
                    context.i18n.settings_delegate_access_description,
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 14.0.s),
                  LabeledCheckbox(
                    isChecked: isChecked.value,
                    onChanged: (value) => isChecked.value = value,
                    label: context.i18n.settings_delegate_access_agree_risks,
                    textStyle: context.theme.appTextThemes.body,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.0.s),
            ScreenSideOffset.small(
              child: Button.compact(
                onPressed: () {
                  if (isChecked.value) {
                    selectAndConfirmUser();
                  }
                },
                label: Text(context.i18n.button_continue),
                type: isChecked.value ? ButtonType.primary : ButtonType.disabled,
                disabled: !isChecked.value,
                minimumSize: Size(double.infinity, 56.0.s),
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
