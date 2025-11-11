// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/role_permissions.dart';
import 'package:ion/generated/assets.gen.dart';

class PermissionItem extends StatelessWidget {
  const PermissionItem({
    required this.permission,
    required this.enabled,
    super.key,
  });

  final GroupPermission permission;
  final bool enabled;

  String _getTitle(BuildContext context) {
    return switch (permission) {
      GroupPermission.deleteMessages => context.i18n.admin_permission_delete_messages,
      GroupPermission.pinMessages => context.i18n.admin_permission_pin_messages,
      GroupPermission.deleteUsers => context.i18n.admin_permission_delete_users,
      GroupPermission.addNewUsers => context.i18n.admin_permission_add_new_users,
      GroupPermission.addNewAdmins => context.i18n.admin_permission_add_new_admins,
      GroupPermission.changeGroupInfo => context.i18n.admin_permission_change_group_info,
      GroupPermission.clearGroup => context.i18n.admin_permission_clear_group,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListItem(
      title: Text(
        _getTitle(context),
        style: context.theme.appTextThemes.body,
      ),
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 8.0.s),
      constraints: BoxConstraints(minHeight: 60.0.s),
      trailing: enabled
          ? Assets.svg.iconAdminStatus.icon(
              size: 24.0.s,
              color: context.theme.appColors.success,
            )
          : Assets.svg.iconBlockClose3.icon(
              size: 24.0.s,
              color: context.theme.appColors.attentionRed,
            ),
    );
  }
}
