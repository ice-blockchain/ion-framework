// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/modal_sheets/simple_modal_sheet.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class LeaveGroupConfirmModal extends StatelessWidget {
  const LeaveGroupConfirmModal({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonMinimalSize = Size(56.0.s, 56.0.s);

    return SimpleModalSheet.alert(
      iconAsset: Assets.svg.actionLeaveGroup,
      title: context.i18n.group_leave_confirm_title,
      description: context.i18n.group_leave_confirm_description,
      button: ScreenSideOffset.small(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Button.compact(
                type: ButtonType.outlined,
                label: Text(context.i18n.button_cancel),
                onPressed: context.pop,
                minimumSize: buttonMinimalSize,
              ),
            ),
            SizedBox(width: 15.0.s),
            Expanded(
              child: Button.compact(
                label: Text(context.i18n.group_leave),
                onPressed: () {
                  context.pop();
                  // TODO: Leave group functionality
                },
                minimumSize: buttonMinimalSize,
                backgroundColor: context.theme.appColors.attentionRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
