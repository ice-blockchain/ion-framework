// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';

enum GroupPermission {
  deleteMessages,
  pinMessages,
  deleteUsers,
  addNewUsers,
  addNewAdmins,
  changeGroupInfo,
  clearGroup,
}

class RolePermissions {
  const RolePermissions._();

  static List<GroupPermission> rolePermission(GroupMemberRole role) {
    return switch (role) {
      GroupMemberRoleMember() => <GroupPermission>[],
      GroupMemberRoleAdmin() => <GroupPermission>[
          GroupPermission.deleteMessages,
          GroupPermission.pinMessages,
          GroupPermission.deleteUsers,
          GroupPermission.addNewUsers,
        ],
      GroupMemberRoleOwner() => GroupPermission.values,
      GroupMemberRoleModerator() => <GroupPermission>[],
    };
  }
}
