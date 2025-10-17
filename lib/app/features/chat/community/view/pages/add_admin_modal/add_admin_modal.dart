// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/community_admin_type.dart';
import 'package:ion/app/features/chat/community/providers/community_admins_provider.r.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class AddAdminModal extends HookConsumerWidget {
  const AddAdminModal({
    required this.createChannelFlow,
    super.key,
  });

  final bool createChannelFlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPubkey = useState<String?>(null);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: UserPickerSheet(
        onUserSelected: (masterPubkey) => selectedPubkey.value = masterPubkey,
        selectedPubkeys: selectedPubkey.value != null ? [selectedPubkey.value!] : [],
        selectable: true,
        navigationBar: NavigationAppBar.modal(
          title: Text(context.i18n.channel_create_admins_action),
          showBackButton: false,
          actions: const [
            NavigationCloseButton(),
          ],
        ),
        footer: Column(
          children: [
            const HorizontalSeparator(),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16.0.s,
                horizontal: 44.0.s,
              ),
              child: Button(
                type: selectedPubkey.value == null ? ButtonType.disabled : ButtonType.primary,
                mainAxisSize: MainAxisSize.max,
                minimumSize: Size(56.0.s, 56.0.s),
                leadingIcon: Assets.svg.iconProfileSave.icon(
                  color: context.theme.appColors.onPrimaryAccent,
                ),
                label: Text(
                  context.i18n.button_confirm,
                ),
                onPressed: () {
                  ref
                      .read(communityAdminsProvider.notifier)
                      .setAdmin(selectedPubkey.value!, CommunityAdminType.admin);
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
