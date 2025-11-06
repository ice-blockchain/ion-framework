// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class InviteGroupParticipant extends StatelessWidget {
  const InviteGroupParticipant({
    required this.selectedPubkeys,
    required this.onUserSelected,
    required this.onAddPressed,
    required this.buttonLabel,
    this.navigationTitle,
    this.disabled = false,
    super.key,
  });

  final List<String> selectedPubkeys;
  final void Function(String masterPubkey) onUserSelected;
  final VoidCallback? onAddPressed;
  final String buttonLabel;
  final String? navigationTitle;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: UserPickerSheet(
            selectable: true,
            key: const Key('invite-group-participant'),
            selectedPubkeys: selectedPubkeys,
            onUserSelected: onUserSelected,
            navigationBar: NavigationAppBar.modal(
              title: Text(
                navigationTitle ??
                    context.i18n.group_create_title((selectedPubkeys.length + 1).toString()),
              ),
              showBackButton: false,
              actions: const [
                NavigationCloseButton(),
              ],
            ),
          ),
        ),
        const HorizontalSeparator(),
        ScreenBottomOffset(
          margin: 32.0.s,
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: 16.0.s),
            child: ScreenSideOffset.medium(
              child: Button(
                onPressed: onAddPressed,
                disabled: disabled,
                label: Text(buttonLabel),
                mainAxisSize: MainAxisSize.max,
                trailingIcon: Assets.svg.iconButtonNext.icon(
                  color: context.theme.appColors.onPrimaryAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
