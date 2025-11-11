// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/componentes/group_participant_list_item.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SelectAdministratorModal extends ConsumerWidget {
  const SelectAdministratorModal({
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

    final sortedMembers = groupMetadata.membersSorted;

    return SheetContent(
      body: SizedBox(
        height: 400.0.s,
        child: Column(
          children: [
            NavigationAppBar.modal(
              showBackButton: false,
              actions: [
                NavigationCloseButton(
                  onPressed: () => context.pop(),
                ),
              ],
              title: Text(context.i18n.select_administrator_title),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.0.s, horizontal: 16.0.s),
                itemCount: sortedMembers.length,
                separatorBuilder: (_, int index) {
                  return SizedBox(height: 12.0.s);
                },
                itemBuilder: (_, int index) {
                  final memberRole = sortedMembers[index];
                  final participantMasterkey = memberRole.masterPubkey;
                  final isOwner = memberRole is GroupMemberRoleOwner;
                  final isAdmin = memberRole is GroupMemberRoleAdmin;
                  final isDisabled = isOwner || isAdmin;

                  return GroupParticipantsListItem(
                    participantMasterkey: participantMasterkey,
                    role: memberRole,
                    actionType: ActionType.select,
                    disabled: isDisabled,
                    onTap: () {
                      if (isDisabled) return;
                      ConfirmAdminRoleAssignModalRoute(
                        conversationId: conversationId,
                        participantMasterkey: participantMasterkey,
                      ).push<void>(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
