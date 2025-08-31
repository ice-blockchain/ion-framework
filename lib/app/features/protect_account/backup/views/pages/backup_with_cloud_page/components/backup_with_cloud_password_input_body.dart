// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/warning_card.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_password/password_validation.dart';
import 'package:ion/app/features/components/verify_identity/components/password_input.dart';
import 'package:ion/app/features/protect_account/backup/providers/cloud_stored_recovery_keys_names_provider.r.dart';
import 'package:ion/app/features/protect_account/backup/providers/create_recovery_key_action_notifier.r.dart';
import 'package:ion/app/features/protect_account/backup/providers/recovery_key_cloud_backup_notifier.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/recovery_credentials_enabled_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

final class BackupWithCloudPasswordInputBody extends HookConsumerWidget {
  const BackupWithCloudPasswordInputBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryCredentials = ref.watch(createRecoveryKeyActionNotifierProvider).valueOrNull;
    if (recoveryCredentials == null) {
      throw Exception('Recovery credentials are required to backup with cloud');
    }

    final passwordController = useTextEditingController();
    final passwordConfirmationController = useTextEditingController();
    final passwordsError = useState<String?>(null);
    final passwordInputFocused = useState<bool>(false);
    final passwordConfirmationInputFocused = useState<bool>(false);
    final focusedPasswordValue = useState<String?>(null);
    final backupActionState = ref.watch(recoveryKeyCloudBackupNotifierProvider);

    final formKey = useRef(GlobalKey<FormState>());

    final onFocusedPasswordValue = useCallback(
      (String value) {
        passwordsError.value = null;
        focusedPasswordValue.value = value;
      },
      [],
    );

    useEffect(
      () {
        if (passwordInputFocused.value) {
          focusedPasswordValue.value = passwordController.text;
        }
        if (passwordConfirmationInputFocused.value) {
          focusedPasswordValue.value = passwordConfirmationController.text;
        }
        return null;
      },
      [
        passwordInputFocused.value,
        passwordConfirmationInputFocused.value,
      ],
    );

    ref.displayErrors(recoveryKeyCloudBackupNotifierProvider);

    return ScreenSideOffset.large(
      child: Form(
        key: formKey.value,
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 16.0.s),
                  PasswordInput(
                    controller: passwordController,
                    passwordInputMode: PasswordInputMode.create,
                    errorText: passwordsError.value,
                    onFocused: (value) => passwordInputFocused.value = value,
                    onValueChanged: onFocusedPasswordValue,
                  ),
                  SizedBox(height: 16.0.s),
                  PasswordInput(
                    isConfirmation: true,
                    controller: passwordConfirmationController,
                    passwordInputMode: PasswordInputMode.create,
                    errorText: passwordsError.value,
                    onFocused: (value) => passwordConfirmationInputFocused.value = value,
                    onValueChanged: onFocusedPasswordValue,
                  ),
                  SizedBox(height: 16.0.s),
                  PasswordValidation(
                    password: focusedPasswordValue.value,
                    showValidation:
                        passwordInputFocused.value || passwordConfirmationInputFocused.value,
                  ),
                  SizedBox(height: 8.0.s),
                  WarningCard(
                    text: context.i18n.backup_cloud_page_password_warning,
                    borderColor: context.theme.appColors.onTertiaryFill,
                    backgroundColor: context.theme.appColors.secondaryBackground,
                  ),
                  ConstrainedBox(constraints: BoxConstraints(minHeight: 16.0.s)),
                ],
              ),
            ),
            ScreenBottomOffset(
              margin: 16.0.s,
              child: Button(
                label: Text(context.i18n.button_continue),
                mainAxisSize: MainAxisSize.max,
                disabled: backupActionState.isLoading,
                trailingIcon: backupActionState.isLoading ? const IONLoadingIndicator() : null,
                onPressed: () async {
                  if (passwordController.text != passwordConfirmationController.text) {
                    passwordsError.value = context.i18n.error_passwords_are_not_equal;
                    return;
                  }
                  if (formKey.value.currentState!.validate()) {
                    await ref.read(recoveryKeyCloudBackupNotifierProvider.notifier).backup(
                          password: passwordController.text,
                          recoveryData: recoveryCredentials,
                        );
                    final state = ref.read(recoveryKeyCloudBackupNotifierProvider);
                    if (!state.hasError && context.mounted) {
                      ref.read(recoveryCredentialsEnabledProvider.notifier).setEnabled();
                      ref.invalidate(cloudStoredRecoveryKeysNamesProvider);
                      await BackupWithCloudSuccessRoute().push<void>(context);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
