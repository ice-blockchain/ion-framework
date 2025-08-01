// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/report_user_modal/types/report_reason_type.dart';
import 'package:ion/generated/assets.gen.dart';

class ReportOptionsSelectorButton extends StatelessWidget {
  const ReportOptionsSelectorButton({
    required this.state,
    required this.isOpened,
    required this.controller,
    super.key,
  });

  final FormFieldState<ReportReasonType?> state;
  final ValueNotifier<bool> isOpened;
  final MenuController controller;

  @override
  Widget build(BuildContext context) {
    final iconBorderSize = Border.fromBorderSide(
      BorderSide(color: context.theme.appColors.onTertiaryFill, width: 1.0.s),
    );

    return Button.dropdown(
      useDefaultBorderRadius: true,
      useDefaultPaddings: true,
      backgroundColor: context.theme.appColors.secondaryBackground,
      borderColor: state.hasError
          ? context.theme.appColors.attentionRed
          : context.theme.appColors.strokeElements,
      leadingIcon: ButtonIconFrame(
        color: context.theme.appColors.tertiaryBackground,
        icon: (state.value?.iconAsset ?? Assets.svg.iconSelect2).icon(
          size: 20.0.s,
          color: context.theme.appColors.secondaryText,
        ),
        border: iconBorderSize,
      ),
      label: SizedBox(
        width: double.infinity,
        child: Text(
          state.value?.getDisplayName(context) ?? context.i18n.dropdown_select_category,
        ),
      ),
      opened: isOpened.value,
      onPressed: () {
        isOpened.value = !isOpened.value;
        if (controller.isOpen) {
          controller.close();
        } else {
          controller.open();
        }
      },
    );
  }
}
