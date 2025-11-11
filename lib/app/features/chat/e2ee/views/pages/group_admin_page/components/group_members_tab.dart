// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/model/group_metadata.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/add_members_button.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/componentes/group_participant_list_item.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class GroupMembersTab extends HookConsumerWidget {
  const GroupMembersTab({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;

    if (groupMetadata == null) {
      return const SizedBox.shrink();
    }

    final members = groupMetadata.members;

    if (members.isEmpty) {
      return Center(
        child: Text(
          context.i18n.group_no_members,
          style: context.theme.appTextThemes.body,
        ),
      );
    }

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserRole = currentUserMasterPubkey != null
        ? groupMetadata.currentUserRole(currentUserMasterPubkey)
        : null;

    final canRemoveMembers = currentUserRole?.canRemoveMembers ?? false;
    final isOwner = currentUserRole is GroupMemberRoleOwner;

    // Sort members so that owner comes first
    final sortedMembers = groupMetadata.membersSorted;

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8.0.s, horizontal: 16.0.s),
      itemCount: sortedMembers.length + (isOwner ? 1 : 0),
      separatorBuilder: (_, int index) {
        return SizedBox(height: 12.0.s);
      },
      itemBuilder: (_, int i) {
        // Show AddMembersButton first if user is owner
        if (isOwner && i == 0) {
          return Padding(
            padding: EdgeInsetsGeometry.only(
              top: 10.0.s,
            ),
            child: AddMembersButton(
              onTap: () {
                AddGroupParticipantsModalRoute(conversationId: conversationId).push<void>(context);
              },
            ),
          );
        }

        // Adjust index for member items when AddMembersButton is present
        final memberIndex = isOwner ? i - 1 : i;
        final memberRole = sortedMembers[memberIndex];
        final participantMasterkey = memberRole.masterPubkey;

        return GroupParticipantsListItem(
          participantMasterkey: participantMasterkey,
          role: memberRole,
          actionType: canRemoveMembers ? ActionType.remove : null,
          onActionTap: () {
            final userPreviewData =
                ref.read(userPreviewDataProvider(participantMasterkey)).valueOrNull;
            if (userPreviewData != null) {
              final userNickname = prefixUsername(
                username: userPreviewData.data.name,
                context: context,
              );
              DeleteGroupUserConfirmRoute(
                userNickname: userNickname,
                conversationId: conversationId,
                participantMasterPubkey: participantMasterkey,
              ).push<void>(context);
            }
          },
          onTap: () {
            ProfileRoute(pubkey: participantMasterkey).push<void>(context);
          },
        );
      },
    );
  }
}
