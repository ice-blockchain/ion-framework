// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_text_button.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/core/providers/theme_mode_provider.r.dart';
import 'package:ion/app/hooks/use_countdown.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/utils/validators.dart';

class TwoFaCodeInput extends HookWidget {
  const TwoFaCodeInput({
    required this.controller,
    required this.twoFaType,
    this.onRequestCode,
    this.isSending = false,
    this.prefixIcon,
    this.countdownInitially = false,
    super.key,
  });

  final TextEditingController controller;
  final TwoFaType twoFaType;
  final Future<void> Function()? onRequestCode;
  final bool isSending;
  final Widget? prefixIcon;
  final bool countdownInitially;

  @override
  Widget build(BuildContext context) {
    return TextInput(
      restorationId: 'twofa_code_input',
      prefixIcon: TextInputIcons(
        hasRightDivider: true,
        icons: [prefixIcon ?? twoFaType.iconAsset.icon()],
      ),
      labelText: twoFaType.getDisplayName(context),
      controller: controller,
      validator: (String? value) {
        if (Validators.isEmpty(value)) return '';
        return null;
      },
      textInputAction: TextInputAction.next,
      scrollPadding: EdgeInsetsDirectional.only(bottom: 200.0.s),
      keyboardType: TextInputType.number,
      suffixIcon: onRequestCode == null
          ? null
          : switch (twoFaType) {
              TwoFaType.email || TwoFaType.sms => SendButton(
                  onRequestCode: onRequestCode,
                  isSending: isSending,
                  countdownInitially: countdownInitially,
                ),
              TwoFaType.auth => null,
            },
    );
  }
}

class SendButton extends HookConsumerWidget {
  const SendButton({
    this.onRequestCode,
    this.isSending = false,
    this.countdownInitially = false,
    super.key,
  });

  final Future<void> Function()? onRequestCode;
  final bool isSending;
  final bool countdownInitially;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSent = useState(countdownInitially);
    final countdownState = useCountdown(60);
    final countdown = countdownState.countdown;
    final startCountdown = countdownState.startCountdown;

    final isLightTheme = ref.watch(appThemeModeProvider) == ThemeMode.light;

    useOnInit(() {
      if (countdownInitially) {
        startCountdown();
      }
    });

    return countdown.value > 0
        ? Padding(
            padding: EdgeInsets.all(14.0.s),
            child: Text(
              context.i18n.common_seconds(countdown.value),
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.tertiaryText,
              ),
            ),
          )
        : isSending
            ? Padding(
                padding: EdgeInsetsDirectional.only(end: 16.0.s),
                child: IONLoadingIndicator(
                  type: isLightTheme ? IndicatorType.dark : IndicatorType.light,
                ),
              )
            : TextInputTextButton(
                onPressed: () {
                  onRequestCode?.call().then((_) {
                    isSent.value = true;
                    startCountdown();
                  });
                },
                label: isSent.value ? context.i18n.button_retry : context.i18n.button_send,
              );
  }
}
