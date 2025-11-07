// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SelectDelegateUserModal extends StatelessWidget {
  const SelectDelegateUserModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      topPadding: 0,
      body: UserPickerSheet(
        navigationBar: NavigationAppBar.modal(
          onBackPress: () => context.maybePop(),
          title: const Text('Select user'), // TODO: add i18n
          actions: const [NavigationCloseButton()],
        ),
        onUserSelected: (masterPubkey) async {
          if (!context.mounted) return;

          final confirmed = await DelegateUserSelectedRoute(
            selectedUserPubkey: masterPubkey,
          ).push<bool>(context);

          // Если вернулись назад (null), остаемся на экране выбора пользователя
          if (confirmed == null && context.mounted) {
            // Остаемся на экране выбора пользователя
            return;
          }
        },
      ),
    );
  }
}
