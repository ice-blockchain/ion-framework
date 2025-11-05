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
  return UpdateGroupChatMembersService(
    mediaEncryptionService: ref.read(mediaEncryptionServiceProvider),
    sendE2eeGroupChatMessageService: ref.read(sendE2eeGroupChatMessageServiceProvider),
    getGroupMetadata: (String groupId) async =>
        await ref.read(encryptedGroupMetadataProvider(groupId).future),
  );
}

class UpdateGroupChatMembersService {
  UpdateGroupChatMembersService({
    required this.mediaEncryptionService,
    required this.sendE2eeGroupChatMessageService,
    required this.getGroupMetadata,
  });

  final MediaEncryptionService mediaEncryptionService;
  final SendE2eeGroupChatMessageService sendE2eeGroupChatMessageService;
  final Future<GroupMetadata?> Function(String groupId) getGroupMetadata;

  Future<MediaFile?> _prepareGroupPicture(GroupMetadata groupMetadata) async {
    if (groupMetadata.avatar.media == null) {
      return null;
    }

    final decryptedFile = await mediaEncryptionService.getEncryptedMedia(
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
    final groupMetadata = await getGroupMetadata(groupId);

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
      sendE2eeGroupChatMessageService.sendMetadataMessage(
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
    final groupMetadata = await getGroupMetadata(groupId);

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
      sendE2eeGroupChatMessageService.sendMetadataMessage(
        members: updatedMembers,
        groupPicture: groupPicture,
        groupId: groupId,
        groupName: groupMetadata.name,
      ),
    );
  }
}
