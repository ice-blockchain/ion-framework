// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'group_member_role.f.freezed.dart';

@freezed
sealed class GroupMemberRole with _$GroupMemberRole {
  const factory GroupMemberRole.admin(String masterPubkey) = GroupMemberRoleAdmin;
  const factory GroupMemberRole.moderator(String masterPubkey) = GroupMemberRoleModerator;
  const factory GroupMemberRole.owner(String masterPubkey) = GroupMemberRoleOwner;
  const factory GroupMemberRole.member(String masterPubkey) = GroupMemberRoleMember;

  const GroupMemberRole._();

  factory GroupMemberRole.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    } else if (tag.length == 2) {
      return GroupMemberRole.member(tag[1]);
    } else if (tag.length < 4) {
      throw Exception('Invalid member role tag length: ${tag.length}');
    }

    return switch (tag[3]) {
      'admin' => GroupMemberRole.admin(tag[1]),
      'moderator' => GroupMemberRole.moderator(tag[1]),
      'owner' => GroupMemberRole.owner(tag[1]),
      '' => GroupMemberRole.member(tag[1]),
      _ => throw Exception('Unknown member role: ${tag[3]}'),
    };
  }

  static const String tagName = 'p';

  @override
  String get masterPubkey => switch (this) {
        GroupMemberRoleAdmin(:final masterPubkey) => masterPubkey,
        GroupMemberRoleModerator(:final masterPubkey) => masterPubkey,
        GroupMemberRoleOwner(:final masterPubkey) => masterPubkey,
        GroupMemberRoleMember(:final masterPubkey) => masterPubkey,
      };

  String get roleName => switch (this) {
        GroupMemberRoleAdmin() => 'admin',
        GroupMemberRoleOwner() => 'owner',
        GroupMemberRoleModerator() => 'moderator',
        GroupMemberRoleMember() => '',
      };

  List<String> toTag() {
    return [tagName, masterPubkey, '', roleName];
  }
}
