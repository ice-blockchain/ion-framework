// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SendProfileModal extends StatelessWidget {
  const SendProfileModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      topPadding: 0,
      body: UserPickerSheet(
        navigationBar: NavigationAppBar.modal(
          showBackButton: false,
          title: Text(context.i18n.chat_profile_share_modal_title),
          actions: [NavigationCloseButton(onPressed: () => context.pop())],
        ),
        onUserSelected: (masterPubkey) => context.pop<String>(masterPubkey),
      ),
    );
  }
}
