// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/components/errors/recover_invalid_credentials_error_alert.dart';
import 'package:ion/app/features/protect_account/backup/data/models/recovery_key_property.dart';
import 'package:ion/app/features/protect_account/backup/providers/recover_user_action_notifier.m.dart';
import 'package:ion/app/features/protect_account/backup/views/components/recovery_key_input.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class RecoveryCredsStep extends HookConsumerWidget {
  const RecoveryCredsStep({
    required this.onContinuePressed,
    super.key,
  });

  final void Function(String name, String id, String code) onContinuePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitLoading = ref.watch(
      initUserRecoveryActionNotifierProvider.select((it) => it.isLoading),
    );
    final isCompleteLoading = ref.watch(
      completeUserRecoveryActionNotifierProvider.select((it) => it.isLoading),
    );
    final formKey = useRef(GlobalKey<FormState>());
    final controllers = {
      for (final key in RecoveryKeyProperty.values) key: useTextEditingController(),
    };
    final validationMode = useState(AutovalidateMode.disabled);

    return SheetContent(
      topPadding: 0,
      body: KeyboardDismissOnTap(
        child: AuthScrollContainer(
          title: context.i18n.restore_identity_title,
          description: context.i18n.restore_identity_creds_description,
          icon: Assets.svg.iconLoginRestorekey.icon(size: 36.0.s),
          titleStyle: context.theme.appTextThemes.headline2,
          descriptionStyle: context.theme.appTextThemes.body2.copyWith(
            color: context.theme.appColors.tertiaryText,
          ),
          children: [
            Expanded(
              child: ScreenSideOffset.large(
                child: Form(
                  key: formKey.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 60.0.s),
                          ...RecoveryKeyProperty.values.map(
                            (key) => Padding(
                              padding: EdgeInsetsDirectional.only(bottom: 16.0.s),
                              child: RecoveryKeyInput(
                                controller: controllers[key]!,
                                labelText: key.getDisplayName(context),
                                prefixIcon: key.iconAsset
                                    .icon(color: context.theme.appColors.secondaryText),
                                validator: (value) => value == null || value.isEmpty ? '' : null,
                                textInputAction: key == RecoveryKeyProperty.recoveryCode
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                autoValidateMode: validationMode.value,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.0.s),
                          Button(
                            label: Text(context.i18n.button_restore),
                            mainAxisSize: MainAxisSize.max,
                            disabled: isInitLoading || isCompleteLoading,
                            trailingIcon: isInitLoading ? const IONLoadingIndicator() : null,
                            onPressed: () {
                              if (formKey.value.currentState!.validate()) {
                                onContinuePressed(
                                  controllers[RecoveryKeyProperty.identityKeyName]!.text,
                                  controllers[RecoveryKeyProperty.recoveryKeyId]!.text,
                                  controllers[RecoveryKeyProperty.recoveryCode]!.text,
                                );
                              } else {
                                validationMode.value = AutovalidateMode.onUserInteraction;
                                showSimpleBottomSheet<void>(
                                  context: context,
                                  child: const RecoverInvalidCredentialsErrorAlert(),
                                );
                              }
                            },
                          ),
                          SizedBox(height: 16.0.s),
                        ],
                      ),
                      const ScreenBottomOffset(child: AuthFooter()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
