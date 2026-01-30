// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class EditUserButton extends ConsumerWidget {
  const EditUserButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      onPressed: () {
        ProfileEditRoute().push<void>(context);
      },
      leadingIcon: Assets.svg.iconEditLink.icon(
        color: context.theme.appColors.onPrimaryAccent,
        size: 16.0.s,
      ),
      tintColor: context.theme.appColors.primaryAccent,
      label: Text(
        context.i18n.profile_edit,
        style: context.theme.appTextThemes.caption.copyWith(
          color: context.theme.appColors.onPrimaryAccent,
          fontSize: 12.0.s,
        ),
        textScaler: TextScaler.noScaling,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(87.0.s, 28.0.s),
        padding: EdgeInsets.symmetric(horizontal: 18.0.s),
      ),
    );
  }
}
