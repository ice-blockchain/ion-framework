// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/riverpod.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_twofa_page/components/twofa_code_input.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_twofa_page/components/twofa_try_again_page.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/request_twofa_code_notifier.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/selected_two_fa_types_provider.m.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class TwoFAInputStep extends HookConsumerWidget {
  const TwoFAInputStep({
    required this.identityKeyName,
    required this.onContinuePressed,
    required this.onBackPress,
    this.isLoading = false,
    this.titleIcon,
    super.key,
  });

  final String identityKeyName;
  final void Function(Map<TwoFaType, String>) onContinuePressed;
  final VoidCallback onBackPress;
  final bool isLoading;
  final Widget? titleIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRequesting = ref.watch(
      requestTwoFaCodeNotifierProvider.select(
        (value) => value.isLoading,
      ),
    );

    _listenRequestTwoFaErrorResult(context, ref);

    final twoFaTypes = ref.watch(selectedTwoFaOptionsProvider);

    final formKey = useRef(GlobalKey<FormState>());
    final controllers = {
      for (final type in twoFaTypes) type: useTextEditingController(),
    };

    return SheetContent(
      topPadding: 0,
      body: AuthScrollContainer(
        title: context.i18n.two_fa_title,
        description: context.i18n.two_fa_desc,
        icon: titleIcon ?? Assets.svg.iconWalletProtectFill.icon(size: 36.0.s),
        onBackPress: onBackPress,
        children: [
          Column(
            children: [
              ScreenSideOffset.large(
                child: Form(
                  key: formKey.value,
                  child: Column(
                    children: [
                      SizedBox(height: 16.0.s),
                      ...[
                        for (final twoFaType in twoFaTypes)
                          Padding(
                            padding: EdgeInsetsDirectional.only(bottom: 16.0.s),
                            child: TwoFaCodeInput(
                              controller: controllers[twoFaType]!,
                              twoFaType: twoFaType,
                              onRequestCode: () => _requestRecoveryCode(ref, twoFaType),
                              isSending: isRequesting,
                            ),
                          ),
                      ],
                      SizedBox(height: 16.0.s),
                      Button(
                        disabled: isLoading,
                        trailingIcon: isLoading ? const IONLoadingIndicator() : null,
                        onPressed: () {
                          if (formKey.value.currentState!.validate()) {
                            _onConfirm(ref, controllers);
                          }
                        },
                        label: Text(context.i18n.button_confirm),
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

  void _onConfirm(WidgetRef ref, Map<TwoFaType, TextEditingController> controllers) {
    onContinuePressed({
      for (final entry in controllers.entries) entry.key: entry.value.text,
    });
  }

  void _listenRequestTwoFaErrorResult(
    BuildContext context,
    WidgetRef ref,
  ) {
    ref.listenError(requestTwoFaCodeNotifierProvider, (error) {
      if (error is TwoFaMethodNotConfiguredException) {
        showSimpleBottomSheet<void>(
          context: ref.context,
          child: TwoFaTryAgainPage(
            description: context.i18n.two_fa_failure_method_not_configured_desc,
          ),
        );
      }
    });
  }

  Future<void> _requestRecoveryCode(
    WidgetRef ref,
    TwoFaType twoFaType,
  ) async {
    if (twoFaType == TwoFaType.auth) {
      return;
    }
    await ref
        .read(requestTwoFaCodeNotifierProvider.notifier)
        .requestRecoveryTwoFaCode(twoFaType, identityKeyName);
  }
}
