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
import 'package:ion/app/features/auth/hooks/use_verify_email_early_access_error_message.dart';
import 'package:ion/app/features/auth/providers/early_access_provider.r.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/email_input.dart';
import 'package:ion/app/features/user/providers/user_verify_identity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class SignUpEarlyAccessPage extends HookConsumerWidget {
  const SignUpEarlyAccessPage({super.key});

  static double get _footerHeight => 92.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPasskeyAvailable = ref.watch(isPasskeyAvailableProvider).valueOrNull ?? false;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final earlyAccessState = ref.watch(earlyAccessNotifierProvider);

    final email = ref.watch(earlyAccessEmailProvider);
    final verifyEmailEarlyAccessErrorMessage = useVerifyEmailEarlyAccessErrorMessage(ref);

    return SheetContent(
      body: KeyboardDismissOnTap(
        child: AuthScrollContainer(
          title: context.i18n.early_access_title,
          description: context.i18n.early_access_desc,
          icon: Assets.svg.iconEmailconfirm.icon(size: 36.0.s),
          children: [
            ScreenSideOffset.large(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    SizedBox(height: 60.0.s),
                    EmailInput(
                      errorText: verifyEmailEarlyAccessErrorMessage.value,
                      initialValue: email,
                      onChanged: (newValue) {
                        verifyEmailEarlyAccessErrorMessage.value = null;
                        ref.read(earlyAccessEmailProvider.notifier).update(newValue);
                      },
                    ),
                    SizedBox(height: 16.0.s),
                    Button(
                      disabled: earlyAccessState.isLoading,
                      trailingIcon: earlyAccessState.isLoading
                          ? const IONLoadingIndicator()
                          : Assets.svg.iconButtonNext
                              .icon(color: context.theme.appColors.onPrimaryAccent),
                      onPressed: () async {
                        if (formKey.currentState!.validate() && email != null) {
                          await ref
                              .read(earlyAccessNotifierProvider.notifier)
                              .verifyEmail(email: email);
                          if (ref.read(earlyAccessNotifierProvider).hasError ||
                              context.mounted == false) {
                            return;
                          }
                          if (isPasskeyAvailable) {
                            final result = await SignUpPasskeyRoute().push<bool>(context);
                            if (result == null || result) {
                              return;
                            }
                          }
                          if (context.mounted) {
                            unawaited(SignUpPasswordRoute().push<void>(context));
                          }
                        }
                      },
                      label: Text(context.i18n.button_continue),
                      mainAxisSize: MainAxisSize.max,
                    ),
                    SizedBox(
                      height: 120.0.s,
                    ),
                    const AuthFooter(),
                  ],
                ),
              ),
            ),
            ScreenBottomOffset(margin: _footerHeight),
          ],
        ),
      ),
    );
  }
}
