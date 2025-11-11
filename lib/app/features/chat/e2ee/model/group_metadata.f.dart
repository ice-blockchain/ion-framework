// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';

part 'group_metadata.f.freezed.dart';

@freezed
class GroupMetadata with _$GroupMetadata {
  const factory GroupMetadata({
    required String id,
    required String name,
    required ({String masterPubkey, MediaAttachment? media}) avatar,
    required List<GroupMemberRole> members,
  }) = _GroupMetadata;

  const GroupMetadata._();

  GroupMemberRole? currentUserRole(String currentUserMasterPubkey) {
    return members.firstWhereOrNull(
      (member) => member.masterPubkey == currentUserMasterPubkey,
    );
  }

  /// Returns members sorted with owner first, then other members
  List<GroupMemberRole> get membersSorted {
    return [...members]..sort((a, b) {
        final aIsOwner = a is GroupMemberRoleOwner;
        final bIsOwner = b is GroupMemberRoleOwner;
        if (aIsOwner && !bIsOwner) {
          return -1;
        }
        if (!aIsOwner && bIsOwner) {
          return 1;
        }
        return 0;
      });
  }
}

extension GroupMemberRoleExtension on GroupMemberRole {
  bool get canRemoveMembers => switch (this) {
        GroupMemberRoleAdmin() => true,
        GroupMemberRoleOwner() => true,
        _ => false,
      };

  bool get canEditGroup => switch (this) {
        GroupMemberRoleAdmin() => false,
        GroupMemberRoleOwner() => true,
        _ => false,
      };
}
