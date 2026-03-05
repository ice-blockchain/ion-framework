// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/community_admin_type.dart';
import 'package:ion/app/features/chat/community/providers/community_admins_provider.r.dart';
import 'package:ion/app/features/chat/community/view/pages/admin_type_selection_modal/components/delete_admin_button.dart';
import 'package:ion/app/features/chat/views/components/selection_list_item.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class AdminTypeSelectionModal extends HookConsumerWidget {
  const AdminTypeSelectionModal({
    required this.adminPubkey,
    required this.adminType,
    required this.createChannelFlow,
    super.key,
  });

  final String adminPubkey;
  final CommunityAdminType adminType;
  final bool createChannelFlow;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAdminType = useState(adminType);

    final adminTypes = useMemoized(
      () {
        if (createChannelFlow) {
          return CommunityAdminType.values.where((e) => e != CommunityAdminType.owner).toList();
        }
        return CommunityAdminType.values;
      },
      [createChannelFlow],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          actions: [
            NavigationCloseButton(
              onPressed: () => context.pop(),
            ),
          ],
          title: Text(context.i18n.channel_create_admin_type_title),
        ),
        for (final CommunityAdminType adminType in adminTypes)
          ScreenSideOffset.small(
            child: Column(
              children: [
                SelectionListItem(
                  title: adminType.getTitle(context),
                  onTap: () {
                    selectedAdminType.value = adminType;
                    ref.read(communityAdminsProvider.notifier).setAdmin(adminPubkey, adminType);
                  },
                  iconAsset: adminType.iconAsset,
                  isSelected: selectedAdminType.value == adminType,
                ),
                SizedBox(height: 16.0.s),
              ],
            ),
          ),
        DeleteAdminButton(
          pubkey: adminPubkey,
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
