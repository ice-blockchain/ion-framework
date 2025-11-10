// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_role_action_item.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ManageOwnerRoleModal extends ConsumerWidget {
  const ManageOwnerRoleModal({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            actions: [
              NavigationCloseButton(
                onPressed: () => context.pop(),
              ),
            ],
            title: Text(context.i18n.channel_create_admin_type_owner),
          ),
          SizedBox(height: 16.0.s),
          GroupRoleActionItem(
            title: context.i18n.transfer_ownership,
            iconAsset: Assets.svg.iconSwap,
            iconColor: context.theme.appColors.primaryAccent,
            onTap: () {
              TransferOwnershipPageRoute(conversationId: conversationId).push<void>(context);
            },
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }
}
