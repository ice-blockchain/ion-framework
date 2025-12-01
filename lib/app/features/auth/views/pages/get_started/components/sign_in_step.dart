// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/login_action_notifier.r.dart';
import 'package:ion/app/features/auth/providers/registration_restrictions_provider.r.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/pages/get_started/components/login_form.dart';
import 'package:ion/app/features/auth/views/pages/get_started/get_started.dart';
import 'package:ion/app/features/components/biometrics/hooks/use_on_suggest_biometrics.dart';
import 'package:ion/app/features/components/passkey/hooks/use_on_suggest_to_create_local_passkey_creds.dart';
import 'package:ion/app/features/components/passkey/no_local_passkey_creds_popup.dart';
import 'package:ion/app/features/user/providers/user_verify_identity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

typedef PromptSignInDialogCallback = Future<String?> Function(
  WidgetRef ref, {
  required String identityKeyName,
  required bool localCredsOnly,
  required Map<TwoFaType, String>? twoFaTypes,
});

typedef SuggestBiometricsCallback = Future<void> Function({
  required String password,
  required String username,
});

class SignInStep extends HookConsumerWidget {
  const SignInStep({
    required this.usernameRef,
    required this.twoFAOptions,
    required this.twoFAOptionsCount,
    required this.step,
    required this.showSignInDialog,
    super.key,
  });

  final ObjectRef<String> usernameRef;
  final ObjectRef<Map<TwoFaType, String>?> twoFAOptions;
  final ObjectRef<int> twoFAOptionsCount;
  final ValueNotifier<GetStartedPageStep> step;

  final PromptSignInDialogCallback showSignInDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPasskeyAvailable = ref.watch(isPasskeyAvailableProvider).valueOrNull ?? false;
    final isProcessing = useState(false);

    final onSuggestToCreatePasskeyCreds = useOnSuggestToCreateLocalPasskeyCreds(ref);
    final onSuggestToAddBiometrics = useOnSuggestToAddBiometrics(ref);

    final alreadyAskedRef = useRef(false);

    final loginActionState = ref.watch(loginActionNotifierProvider);
    ref.displayErrors(registrationRestrictionProvider);

    return SheetContent(
      body: KeyboardDismissOnTap(
        child: AuthScrollContainer(
          showBackButton: false,
          actions: const [NavigationCloseButton()],
          title: context.i18n.get_started_title,
          description: context.i18n.get_started_description,
          icon: Assets.svg.iconLoginIcelogo.icon(size: 44.0.s),
          children: [
            ScreenSideOffset.large(
              child: Column(
                children: [
                  SizedBox(height: 56.0.s),
                  LoginForm(
                    onLogin: (username) {
                      usernameRef.value = username;
                      if (username.isEmpty) {
                        _attemptAutoPasskeyLogin(ref, alreadyAskedRef);
                      } else {
                        _handleLoginWithPasswordFallback(
                          ref,
                          username: username,
                          onSuggestToCreatePasskeyCreds: onSuggestToCreatePasskeyCreds,
                          onSuggestToAddBiometrics: onSuggestToAddBiometrics,
                        );
                      }
                    },
                  ),
                  SizedBox(height: 14.0.s),
                  Text(
                    context.i18n.get_started_method_divider,
                    style: context.theme.appTextThemes.caption.copyWith(
                      color: context.theme.appColors.tertiaryText,
                    ),
                  ),
                  SizedBox(height: 14.0.s),
                  Button(
                    type: ButtonType.outlined,
                    disabled: isProcessing.value,
                    trailingIcon: isProcessing.value ? const IONLoadingIndicator() : null,
                    leadingIcon: Assets.svg.iconLoginCreateacc.icon(
                      color: context.theme.appColors.secondaryText,
                    ),
                    onPressed: () async {
                      isProcessing.value = true;
                      try {
                        final registrationRestrictionType =
                            await ref.read(registrationRestrictionProvider.future);
                        if (context.mounted == false) {
                          return;
                        }
                        switch (registrationRestrictionType) {
                          case RegistrationRestrictionType.fullyAllowed:
                            if (isPasskeyAvailable) {
                              final result = await SignUpPasskeyRoute().push<bool>(context);
                              if (result == null || result) {
                                return;
                              }
                            }
                            if (context.mounted) {
                              unawaited(SignUpPasswordRoute().push<void>(context));
                            }
                          case RegistrationRestrictionType.earlyAccessOnly:
                            unawaited(SignUpEarlyAccessRoute().push<void>(context));
                          case RegistrationRestrictionType.restricted:
                            unawaited(SignUpRestrictedRoute().push<void>(context));
                        }
                      } finally {
                        isProcessing.value = false;
                      }
                    },
                    label: Text(context.i18n.button_register),
                    mainAxisSize: MainAxisSize.max,
                  ),
                  SizedBox(height: 16.0.s),
                  Button(
                    labelFlex: 2,
                    type: ButtonType.outlined,
                    leadingIcon: Flexible(
                      child: Assets.svg.iconRestorekey.icon(
                        color: context.theme.appColors.secondaryText,
                      ),
                    ),
                    disabled: loginActionState.isLoading,
                    onPressed: () => RestoreMenuRoute().push<void>(context),
                    label: Text(
                      context.i18n.get_started_restore_button,
                      maxLines: 2,
                    ),
                    mainAxisSize: MainAxisSize.max,
                    borderColor: Colors.transparent,
                  ),
                  SizedBox(height: 16.0.s),
                  ScreenBottomOffset(child: const AuthFooter()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _attemptAutoPasskeyLogin(
    WidgetRef ref,
    ObjectRef<bool> alreadyAskedRef,
  ) {
    if (alreadyAskedRef.value) {
      return;
    }
    alreadyAskedRef.value = true;

    const config = AuthConfig();
    ref.read(loginActionNotifierProvider.notifier).signIn(
          keyName: usernameRef.value,
          config: config,
          twoFaTypes: twoFAOptions.value,
          localCredsOnly: true,
        );
  }

  /// Attempts to sign in using stored credentials or passkey.
  /// Falls back to password prompt and biometric suggestion if necessary.
  Future<void> _handleLoginWithPasswordFallback(
    WidgetRef ref, {
    required String username,
    required Future<void> Function(String username) onSuggestToCreatePasskeyCreds,
    required SuggestBiometricsCallback onSuggestToAddBiometrics,
  }) async {
    final authState = await ref.read(authProvider.future);
    final currentAuthenticatedUsers = authState.authenticatedIdentityKeyNames;

    final isSwitchingToExistingAccount = await ref
        .read(authProvider.notifier)
        .handleSwitchingToExistingAccount(username, currentAuthenticatedUsers);
    if (isSwitchingToExistingAccount) return;

    await ref.read(loginActionNotifierProvider.notifier).verifyUserLoginFlow(keyName: username);
    final loginState = ref.read(loginActionNotifierProvider);
    if (loginState.hasError) {
      if (loginState.error is TwoFARequiredException) {
        final e = loginState.error! as TwoFARequiredException;
        twoFAOptionsCount.value = e.twoFAOptionsCount;
        step.value = GetStartedPageStep.twoFAOptions;
      }
    } else {
      final loginPassword = await showSignInDialog(
        ref,
        identityKeyName: usernameRef.value,
        localCredsOnly: true,
        twoFaTypes: twoFAOptions.value,
      );

      if (ref.context.mounted) {
        final loginState = ref.read(loginActionNotifierProvider);
        if (loginState.hasError) {
          if (ref.context.mounted &&
              loginState.error is NoLocalPasskeyCredsFoundIONIdentityException) {
            final proceed = await showSimpleBottomSheet<bool>(
              context: ref.context,
              child: const NoLocalPasskeyCredsPopup(),
            );
            if (ref.context.mounted && proceed != null && proceed) {
              await showSignInDialog(
                ref,
                identityKeyName: usernameRef.value,
                localCredsOnly: false,
                twoFaTypes: twoFAOptions.value,
              );
              if (ref.context.mounted && !ref.read(loginActionNotifierProvider).hasError) {
                await onSuggestToCreatePasskeyCreds(username);
              }
            }
          }
        } else if (loginPassword != null) {
          await onSuggestToAddBiometrics(
            username: username,
            password: loginPassword,
          );
        }
      }
    }
  }
}
