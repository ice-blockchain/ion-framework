// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_role_action_item.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ManageAdminRoleModal extends ConsumerWidget {
  const ManageAdminRoleModal({
    required this.conversationId,
    required this.participantMasterkey,
    super.key,
  });

  final String conversationId;
  final String participantMasterkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            onBackPress: () => context.pop(),
            title: Text(context.i18n.channel_create_admin_type_title),
          ),
          SizedBox(height: 16.0.s),
          GroupRoleActionItem(
            title: context.i18n.channel_create_admin_type_remove,
            onTap: () {
              RemoveAdminRoleConfirmModalRoute(
                conversationId: conversationId,
                participantMasterPubkey: participantMasterkey,
              ).push<void>(context);
            },
            iconAsset: Assets.svg.iconBlockDelete,
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }
}
