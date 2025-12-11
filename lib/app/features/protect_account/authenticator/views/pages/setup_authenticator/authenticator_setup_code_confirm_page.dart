// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header_icon.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_twofa_page/components/twofa_try_again_page.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/security_account_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/show_close_button_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/validate_twofa_code_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class AuthenticatorSetupCodeConfirmPage extends HookConsumerWidget {
  const AuthenticatorSetupCodeConfirmPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final formKey = useRef(GlobalKey<FormState>());
    final codeFailed = useState<bool>(false);

    ref.listenSuccess(validateTwoFaCodeNotifierProvider, (_) => _onSuccess(context, ref));
    _listenValidateTwoFaErrorResult(context, ref, codeFailed);

    return SheetContent(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            primary: false,
            flexibleSpace: NavigationAppBar.modal(
              showCloseButton: ref.watch(showCloseButtonProvider),
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
                  title: context.i18n.confirm_the_code_title,
                  description: context.i18n.follow_instructions_description,
                  titleStyle: context.theme.appTextThemes.headline2,
                  descriptionStyle: context.theme.appTextThemes.body2.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                  icon: AuthHeaderIcon(
                    icon: Assets.svg.iconLoginPassword.icon(size: 36.0.s),
                  ),
                ),
                SizedBox(height: 32.0.s),
                Expanded(
                  child: Form(
                    key: formKey.value,
                    child: Center(
                      child: ScreenSideOffset.large(
                        child: TextInput(
                          controller: controller,
                          labelText: context.i18n.two_fa_auth,
                          prefixIcon: TextInputIcons(
                            hasRightDivider: true,
                            icons: [Assets.svg.iconRecoveryCode.icon()],
                          ),
                          validator: (value) => (value?.isEmpty ?? false) ? '' : null,
                          textInputAction: TextInputAction.done,
                          scrollPadding: EdgeInsetsDirectional.only(bottom: 200.0.s),
                          onChanged: (text) => codeFailed.value = false,
                          errorText: codeFailed.value
                              ? context.i18n.two_fa_failure_invalid_code_short
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 22.0.s),
                ScreenSideOffset.large(
                  child: Button(
                    mainAxisSize: MainAxisSize.max,
                    label: Text(context.i18n.button_confirm),
                    type: codeFailed.value ? ButtonType.disabled : ButtonType.primary,
                    onPressed: () => _validateAndProceed(
                      context,
                      ref,
                      formKey.value,
                      controller.value.text,
                    ),
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

  void _validateAndProceed(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState>? formKey,
    String code,
  ) {
    final isFormValid = formKey?.currentState?.validate() ?? false;
    if (!isFormValid) {
      return;
    }

    ref
        .read(validateTwoFaCodeNotifierProvider.notifier)
        .validateTwoFACode(TwoFAType.authenticator(code));
  }

  Future<void> _onSuccess(BuildContext context, WidgetRef ref) async {
    ref.invalidate(securityAccountControllerProvider);

    if (!context.mounted) {
      return;
    }

    await AuthenticatorSetupSuccessRoute().push<void>(context);
  }

  void _listenValidateTwoFaErrorResult(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> failedCodeNotifier,
  ) {
    ref.listenError(validateTwoFaCodeNotifierProvider, (error) {
      if (error is InvalidTwoFaCodeException) {
        failedCodeNotifier.value = true;
        showSimpleBottomSheet<void>(
          context: ref.context,
          child: TwoFaTryAgainPage(description: context.i18n.two_fa_failure_invalid_code_desc),
        );
      }
    });
  }
}
