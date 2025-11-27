// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/protect_account/hooks/use_go_to_secure_account_options.dart';
import 'package:ion/app/features/protect_account/model/two_fa_action_type.dart';

class TwoFaSuccessStep extends HookConsumerWidget {
  const TwoFaSuccessStep({
    required this.actionType,
    super.key,
  });

  final TwoFaActionType actionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;

    final goToSecureAccountOptions = usePopToSecureAccountOptions(ref);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 45.0.s,
        ),
        ScreenSideOffset.medium(
          child: InfoCard(
            iconAsset: actionType.successIconAsset,
            title: locale.common_congratulations,
            description: actionType.getSuccessDesc(context),
          ),
        ),
        SizedBox(
          height: 22.0.s,
        ),
        ScreenSideOffset.large(
          child: Button(
            mainAxisSize: MainAxisSize.max,
            label: Text(locale.button_back_to_security),
            onPressed: goToSecureAccountOptions,
          ),
        ),
        ScreenBottomOffset(margin: 16.0.s),
      ],
    );
  }
}
