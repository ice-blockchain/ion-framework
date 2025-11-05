// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/model/group_metadata.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/send_e2ee_group_chat_message_service.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_group_chat_members_service.r.g.dart';

@riverpod
UpdateGroupChatMembersService updateGroupChatMembersService(Ref ref) {
  return UpdateGroupChatMembersService(ref);
}

class UpdateGroupChatMembersService {
  UpdateGroupChatMembersService(this.ref);

  final Ref ref;

  Future<MediaFile?> _prepareGroupPicture(GroupMetadata groupMetadata) async {
    if (groupMetadata.avatar.media == null) {
      return null;
    }

    final decryptedFile = await ref.read(mediaEncryptionServiceProvider).getEncryptedMedia(
          groupMetadata.avatar.media!,
          authorPubkey: groupMetadata.avatar.masterPubkey,
        );

    return MediaFile(
      path: decryptedFile.path,
      mimeType: groupMetadata.avatar.media!.mimeType,
      originalMimeType: groupMetadata.avatar.media!.originalMimeType,
    );
  }

  Future<void> addMembers({
    required String groupId,
    required List<String> participantMasterPubkeys,
  }) async {
    final groupMetadata = ref.read(encryptedGroupMetadataProvider(groupId)).valueOrNull;

    if (groupMetadata == null) {
      return;
    }

    final existingMemberPubkeys =
        groupMetadata.members.map((member) => member.masterPubkey).toSet();

    final newParticipantPubkeys = participantMasterPubkeys
        .where((pubkey) => !existingMemberPubkeys.contains(pubkey))
        .toList();

    if (newParticipantPubkeys.isEmpty) {
      return;
    }

    // Build new members list: existing members + newly added participants
    final newMembers = <GroupMemberRole>[
      ...groupMetadata.members,
      ...newParticipantPubkeys.map(GroupMemberRole.member),
    ];

    final groupPicture = await _prepareGroupPicture(groupMetadata);

    unawaited(
      ref.read(sendE2eeGroupChatMessageServiceProvider).sendMetadataMessage(
            members: newMembers,
            groupPicture: groupPicture,
            groupId: groupId,
            groupName: groupMetadata.name,
          ),
    );
  }

  Future<void> removeMembers({
    required String groupId,
    required List<String> participantMasterPubkeys,
  }) async {
    final groupMetadata = ref.read(encryptedGroupMetadataProvider(groupId)).valueOrNull;

    if (groupMetadata == null) {
      return;
    }

    // Remove the specified members from the members list
    final updatedMembers = <GroupMemberRole>[
      ...groupMetadata.members
          .where((member) => !participantMasterPubkeys.contains(member.masterPubkey)),
    ];

    // Prepare group picture
    final groupPicture = await _prepareGroupPicture(groupMetadata);

    // Send new metadata message with updated members (don't wait)
    unawaited(
      ref.read(sendE2eeGroupChatMessageServiceProvider).sendMetadataMessage(
            members: updatedMembers,
            groupPicture: groupPicture,
            groupId: groupId,
            groupName: groupMetadata.name,
          ),
    );
  }
}
