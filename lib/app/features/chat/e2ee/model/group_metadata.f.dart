// SPDX-License-Identifier: ice License 1.0

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
}
