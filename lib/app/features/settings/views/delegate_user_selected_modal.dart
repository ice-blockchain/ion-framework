// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class DelegateUserSelectedModal extends ConsumerWidget {
  const DelegateUserSelectedModal({
    required this.selectedUserPubkey,
    super.key,
  });

  final String selectedUserPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              onBackPress: () => context.pop(),
              title: const Text('Access rights'), // TODO: add i18n
              actions: [
                NavigationCloseButton(
                  onPressed: () => rootNavigatorKey.currentState?.pop(),
                ),
              ],
            ),
            ScreenSideOffset.small(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.theme.appColors.tertiaryBackground,
                      borderRadius: BorderRadius.all(Radius.circular(16.0.s)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
                    child: UserInfo(
                      pubkey: selectedUserPubkey,
                      padding: EdgeInsetsDirectional.zero,
                    ),
                  ),
                  SizedBox(height: 20.0.s),
                  Button.compact(
                    onPressed: () {
                      context.pop(true);
                    },
                    label: const Text('Confirm'), // TODO: add i18n
                    minimumSize: Size(double.infinity, 56.0.s),
                  ),
                ],
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
