// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header_icon.dart';
import 'package:ion/app/features/components/verify_identity/hooks/use_on_get_password.dart';
import 'package:ion/app/features/protect_account/authenticator/views/pages/setup_authenticator/components/authenticator_setup_instructions_error_state.dart';
import 'package:ion/app/features/protect_account/authenticator/views/pages/setup_authenticator/components/authenticator_setup_instructions_success_state.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/request_twofa_code_notifier.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class AuthenticatorSetupInstructionsPage extends HookConsumerWidget {
  const AuthenticatorSetupInstructionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onGetPassword = useOnGetPassword<String>();

    final twoFaProvider = ref.watch(requestTwoFaCodeNotifierProvider);
    ref.displayErrors(requestTwoFaCodeNotifierProvider);

    final requestCode = useCallback(() {
      ref.read(requestTwoFaCodeNotifierProvider.notifier).requestTwoFaCode(TwoFaType.auth);
    });

    useOnInit(requestCode, [onGetPassword]);

    return SheetContent(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            primary: false,
            flexibleSpace: NavigationAppBar.modal(
              actions: const [
                NavigationCloseButton(),
              ],
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: NavigationAppBar.modalHeaderHeight,
            pinned: true,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                AuthHeader(
                  title: context.i18n.follow_instructions_title,
                  description: context.i18n.follow_instructions_description,
                  titleStyle: context.theme.appTextThemes.headline2,
                  descriptionStyle: context.theme.appTextThemes.body2.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                  icon: AuthHeaderIcon(
                    icon: Assets.svg.icon2faFollowinstuction.icon(size: 36.0.s),
                  ),
                ),
                SizedBox(height: 32.0.s),
                Expanded(
                  child: ScreenSideOffset.large(
                    child: switch (twoFaProvider) {
                      AsyncError() =>
                        AuthenticatorSetupInstructionsErrorState(onRetry: requestCode),
                      _ => AuthenticatorSetupInstructionsSuccessState(code: twoFaProvider.value),
                    },
                  ),
                ),
                ScreenBottomOffset(margin: 36.0.s),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
