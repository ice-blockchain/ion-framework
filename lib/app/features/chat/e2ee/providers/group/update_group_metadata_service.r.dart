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

part 'update_group_metadata_service.r.g.dart';

@riverpod
UpdateGroupMetaDataService updateGroupMetaDataService(Ref ref) {
  return UpdateGroupMetaDataService(
    mediaEncryptionService: ref.read(mediaEncryptionServiceProvider),
    sendE2eeGroupChatMessageService: ref.read(sendE2eeGroupChatMessageServiceProvider),
    getGroupMetadata: (String groupId) async =>
        await ref.read(encryptedGroupMetadataProvider(groupId).future),
  );
}

class UpdateGroupMetaDataService {
  UpdateGroupMetaDataService({
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

  Future<void> updateMetadata({
    required String groupId,
    String? title,
    MediaFile? newGroupPicture,
  }) async {
    final groupMetadata = await getGroupMetadata(groupId);

    if (groupMetadata == null) {
      return;
    }

    // Use provided title or keep existing one
    final updatedTitle = title ?? groupMetadata.name;

    // Use provided new group picture or prepare existing one
    final groupPicture = newGroupPicture ?? await _prepareGroupPicture(groupMetadata);

    // Keep existing members
    final members = groupMetadata.members;

    unawaited(
      sendE2eeGroupChatMessageService.sendMetadataMessage(
        members: members,
        groupPicture: groupPicture,
        groupId: groupId,
        groupName: updatedTitle,
      ),
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

    final groupPicture = await _prepareGroupPicture(groupMetadata);

    unawaited(
      sendE2eeGroupChatMessageService.sendMetadataMessage(
        members: updatedMembers,
        groupPicture: groupPicture,
        groupId: groupId,
        groupName: groupMetadata.name,
      ),
    );
  }

  Future<void> promoteMemberToAdmin({
    required String groupId,
    required String participantMasterPubkey,
  }) async {
    final groupMetadata = await getGroupMetadata(groupId);

    if (groupMetadata == null) {
      return;
    }

    // Update the member's role to admin, keeping all other members unchanged
    final updatedMembers = groupMetadata.members.map((member) {
      if (member.masterPubkey == participantMasterPubkey) {
        // Only promote if they're currently a member (not owner or already admin)
        if (member is GroupMemberRoleMember) {
          return GroupMemberRole.admin(participantMasterPubkey);
        }
      }
      return member;
    }).toList();

    final groupPicture = await _prepareGroupPicture(groupMetadata);

    unawaited(
      sendE2eeGroupChatMessageService.sendMetadataMessage(
        members: updatedMembers,
        groupPicture: groupPicture,
        groupId: groupId,
        groupName: groupMetadata.name,
      ),
    );
  }

  Future<void> removeAdminRole({
    required String groupId,
    required String participantMasterPubkey,
  }) async {
    final groupMetadata = await getGroupMetadata(groupId);

    if (groupMetadata == null) {
      return;
    }

    // Update the admin's role to member, keeping all other members unchanged
    final updatedMembers = groupMetadata.members.map((member) {
      if (member.masterPubkey == participantMasterPubkey) {
        // Only demote if they're currently an admin (not owner)
        if (member is GroupMemberRoleAdmin) {
          return GroupMemberRole.member(participantMasterPubkey);
        }
      }
      return member;
    }).toList();

    final groupPicture = await _prepareGroupPicture(groupMetadata);

    unawaited(
      sendE2eeGroupChatMessageService.sendMetadataMessage(
        members: updatedMembers,
        groupPicture: groupPicture,
        groupId: groupId,
        groupName: groupMetadata.name,
      ),
    );
  }

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerMasterPubkey,
    required String currentOwnerMasterPubkey,
  }) async {
    final groupMetadata = await getGroupMetadata(groupId);

    if (groupMetadata == null) {
      return;
    }

    // Transfer ownership: make new owner the owner, and current owner becomes a member
    final updatedMembers = groupMetadata.members.map((member) {
      if (member.masterPubkey == newOwnerMasterPubkey) {
        // Make the selected member the new owner
        return GroupMemberRole.owner(newOwnerMasterPubkey);
      } else if (member.masterPubkey == currentOwnerMasterPubkey) {
        // Make the current owner an admin
        return GroupMemberRole.member(currentOwnerMasterPubkey);
      }
      return member;
    }).toList();

    final groupPicture = await _prepareGroupPicture(groupMetadata);

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
