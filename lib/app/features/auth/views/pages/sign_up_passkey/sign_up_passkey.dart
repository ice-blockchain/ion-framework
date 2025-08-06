// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/components/sign_up_list_item/sign_up_list_item.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_passkey/sign_up_passkey_form.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class SignUpPasskeyPage extends StatelessWidget {
  const SignUpPasskeyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      body: KeyboardDismissOnTap(
        child: AuthScrollContainer(
          title: context.i18n.sign_up_passkey_title,
          icon: Assets.svg.iconLoginPasskey.icon(size: 36.0.s),
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ScreenSideOffset.large(
              child: Column(
                children: [
                  SizedBox(height: 37.0.s),
                  SignUpListItem(
                    title: context.i18n.sign_up_passkey_advantage_1_title,
                    subtitle: context.i18n.sign_up_passkey_advantage_1_description,
                    icon: Assets.svg.iconLoginFingerprint.icon(),
                  ),
                  SignUpListItem(
                    title: context.i18n.sign_up_passkey_advantage_2_title,
                    subtitle: context.i18n.sign_up_passkey_advantage_2_description,
                    icon: Assets.svg.iconLoginDevice.icon(),
                  ),
                  SignUpListItem(
                    title: context.i18n.sign_up_passkey_advantage_3_title,
                    subtitle: context.i18n.sign_up_passkey_advantage_3_description,
                    icon: Assets.svg.iconLoginSafeacc.icon(),
                  ),
                  SizedBox(height: 37.0.s),
                  const SignUpPasskeyForm(),
                  ScreenBottomOffset(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
