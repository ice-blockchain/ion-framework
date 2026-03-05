// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/components/identity_key_name_input/identity_key_name_input.dart';
import 'package:ion/app/features/auth/views/pages/restore_creds/recovery_code_input.dart';
import 'package:ion/app/features/auth/views/pages/restore_creds/recovery_key_id_input.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class RestoreCredsPage extends HookWidget {
  const RestoreCredsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useRef(GlobalKey<FormState>());
    final identityKeyNameController = useTextEditingController();
    final recoveryCodeController = useTextEditingController();
    final recoveryKeyIdController = useTextEditingController();

    return SheetContent(
      body: AuthScrollContainer(
        title: context.i18n.restore_identity_title,
        description: context.i18n.restore_identity_creds_description,
        icon: Assets.svg.iconLoginRestorekey.icon(size: 36.0.s),
        children: [
          Column(
            children: [
              ScreenSideOffset.large(
                child: Form(
                  key: formKey.value,
                  child: Column(
                    children: [
                      SizedBox(height: 16.0.s),
                      IdentityKeyNameInput(
                        controller: identityKeyNameController,
                        textInputAction: TextInputAction.next,
                        scrollPadding: EdgeInsetsDirectional.only(bottom: 250.0.s),
                        notShowInfoIcon: true,
                      ),
                      SizedBox(height: 16.0.s),
                      RecoveryCodeInput(
                        controller: recoveryCodeController,
                      ),
                      SizedBox(height: 16.0.s),
                      RecoveryKeyIdInput(
                        controller: recoveryKeyIdController,
                      ),
                      SizedBox(height: 20.0.s),
                      Button(
                        onPressed: () {
                          if (!formKey.value.currentState!.validate()) {}
                        },
                        label: Text(context.i18n.button_restore),
                        mainAxisSize: MainAxisSize.max,
                      ),
                      SizedBox(height: 16.0.s),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const ScreenBottomOffset(child: AuthFooter()),
        ],
      ),
    );
  }
}
