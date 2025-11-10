// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/update_group_metadata_service.r.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/pages/components/invite_group_participant.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class AddGroupParticipantsModal extends HookConsumerWidget {
  const AddGroupParticipantsModal({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;
    final selectedParticipants = useState<Set<String>>({});

    // Initialize and update selectedParticipants with existing members' master pubkeys
    useEffect(
      () {
        if (groupMetadata != null) {
          final existingPubkeys =
              groupMetadata.members.map((member) => member.masterPubkey).toSet();
          selectedParticipants.value = existingPubkeys;
        }
        return null;
      },
      [groupMetadata],
    );

    final existingMemberPubkeysSet =
        groupMetadata?.members.map((member) => member.masterPubkey).toSet() ?? <String>{};
    final hasNewParticipants =
        selectedParticipants.value.any((pubkey) => !existingMemberPubkeysSet.contains(pubkey));
    final isButtonDisabled = !hasNewParticipants;

    return SheetContent(
      topPadding: 0,
      body: InviteGroupParticipant(
        selectedPubkeys: selectedParticipants.value.toList(),
        onUserSelected: (String masterPubkey) {
          final updated = {...selectedParticipants.value};
          if (updated.contains(masterPubkey)) {
            updated.remove(masterPubkey);
          } else {
            updated.add(masterPubkey);
          }
          selectedParticipants.value = updated;
        },
        buttonLabel: context.i18n.button_add,
        onAddPressed: () {
          if (groupMetadata == null) {
            return;
          }

          final existingMemberPubkeys =
              groupMetadata.members.map((member) => member.masterPubkey).toSet();

          final newParticipantPubkeys = selectedParticipants.value
              .where((pubkey) => !existingMemberPubkeys.contains(pubkey))
              .toList();

          if (newParticipantPubkeys.isEmpty) {
            return;
          }

          ref.read(updateGroupMetaDataServiceProvider).addMembers(
                groupId: conversationId,
                participantMasterPubkeys: newParticipantPubkeys,
              );

          if (context.mounted) {
            context.pop();
          }
        },
        disabled: isButtonDisabled,
        navigationTitle: context.i18n.group_add_members_title,
      ),
    );
  }
}
