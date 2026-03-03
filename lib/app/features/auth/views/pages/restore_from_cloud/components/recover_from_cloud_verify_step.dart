// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

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
import 'package:ion/app/features/auth/views/pages/restore_from_cloud/components/identity_key_name_selector.dart';
import 'package:ion/app/features/auth/views/pages/restore_from_cloud/components/recovery_keys_decrypt_password_input.dart';
import 'package:ion/app/features/protect_account/backup/providers/cloud_stored_recovery_keys_names_provider.r.dart';
import 'package:ion/app/features/protect_account/backup/providers/recovery_key_cloud_backup_restore_notifier.r.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class RestoreFromCloudVerifyStep extends HookConsumerWidget {
  const RestoreFromCloudVerifyStep({
    required this.onContinue,
    required this.isLoading,
    super.key,
  });

  final void Function(String identityKeyName, String password) onContinue;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableKeys = ref.watch(cloudStoredRecoveryKeysNamesProvider).valueOrNull ?? {};
    if (availableKeys.isEmpty) {
      throw Exception('No available keys');
    }

    final isSingleKeyAvailable = availableKeys.length == 1;
    final isRestoreLoading =
        ref.watch(recoveryKeyCloudBackupRestoreNotifierProvider.select((it) => it.isLoading)) ||
            isLoading;
    final formKey = useRef(GlobalKey<FormState>());
    final identityKeyNameTextController = useTextEditingController(
      text: isSingleKeyAvailable ? availableKeys.first : '',
    );
    final passwordController = useTextEditingController();

    final cloudType =
        Platform.isIOS ? context.i18n.backup_icloud : context.i18n.backup_google_drive;
    final descriptionCloudType = Platform.isIOS
        ? context.i18n.restore_from_cloud_description_type_icloud
        : context.i18n.restore_from_cloud_description_type_google_drive;

    return SheetContent(
      topPadding: 0,
      body: KeyboardDismissOnTap(
        child: AuthScrollContainer(
          title: context.i18n.restore_identity_from(cloudType),
          description: context.i18n.restore_from_cloud_description(descriptionCloudType),
          icon: Assets.svg.iconLoginRestorecloud.icon(size: 36.0.s),
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
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 24.0.s),
                            IgnorePointer(
                              ignoring: isSingleKeyAvailable,
                              child: IdentityKeyNameSelector(
                                availableOptions: availableKeys,
                                textController: identityKeyNameTextController,
                                initialValue: isSingleKeyAvailable ? availableKeys.first : null,
                              ),
                            ),
                            SizedBox(height: 21.0.s),
                            RecoveryKeysDecryptPasswordInput(controller: passwordController),
                            SizedBox(height: 21.0.s),
                            Button(
                              label: Text(context.i18n.button_restore),
                              mainAxisSize: MainAxisSize.max,
                              disabled: isRestoreLoading,
                              trailingIcon: isRestoreLoading ? const IONLoadingIndicator() : null,
                              onPressed: () {
                                if (formKey.value.currentState!.validate()) {
                                  onContinue(
                                    identityKeyNameTextController.text,
                                    passwordController.text,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 21.0.s),
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
