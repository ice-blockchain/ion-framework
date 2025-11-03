// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/create_group_form_controller_provider.r.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/pages/components/invite_group_participant.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class InitGroupParticipantsModal extends HookConsumerWidget {
  const InitGroupParticipantsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createGroupForm = ref.watch(createGroupFormControllerProvider);
    final createGroupFormNotifier = ref.watch(createGroupFormControllerProvider.notifier);

    return SheetContent(
      topPadding: 0,
      body: InviteGroupParticipant(
        selectedPubkeys: createGroupForm.participantsMasterPubkeys.toList(),
        onUserSelected: createGroupFormNotifier.toggleMember,
        buttonLabel: context.i18n.button_next,
        onAddPressed: () {
          ref.read(searchUsersQueryProvider.notifier).text = '';
          CreateGroupModalRoute().replace(context);
        },
      ),
    );
  }
}
