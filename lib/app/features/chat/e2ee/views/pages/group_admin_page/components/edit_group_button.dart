// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class EditGroupButton extends ConsumerWidget {
  const EditGroupButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      onPressed: () {
        // TODO: Navigate to edit group page
      },
      leadingIcon: Assets.svg.iconEditLink.icon(
        color: context.theme.appColors.onPrimaryAccent,
        size: 16.0.s,
      ),
      tintColor: context.theme.appColors.primaryAccent,
      label: Text(
        context.i18n.group_edit_button,
        style: context.theme.appTextThemes.caption.copyWith(
          color: context.theme.appColors.onPrimaryAccent,
          fontSize: 12.0.s,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(87.0.s, 28.0.s),
        padding: EdgeInsets.symmetric(horizontal: 18.0.s),
      ),
    );
  }
}
