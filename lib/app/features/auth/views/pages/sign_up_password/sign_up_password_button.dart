// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_screen_busy_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class SignUpPasswordButton extends ConsumerWidget {
  const SignUpPasswordButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authScreenIsBusy = ref.watch(authScreenBusyProvider);

    return Button(
      disabled: authScreenIsBusy,
      trailingIcon: authScreenIsBusy
          ? const IONLoadingIndicator()
          : Assets.svg.iconButtonNext.icon(color: context.theme.appColors.onPrimaryAccent),
      onPressed: authScreenIsBusy ? null : onPressed,
      label: Text(context.i18n.button_continue),
      mainAxisSize: MainAxisSize.max,
    );
  }
}
