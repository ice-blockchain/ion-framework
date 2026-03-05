// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/providers/community_admins_provider.r.dart';
import 'package:ion/app/features/chat/community/view/pages/add_admin_modal/add_admin_modal.dart';
import 'package:ion/app/features/chat/community/view/pages/admins_management_modal/components/admin_card.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class AdminsManagementModal extends HookConsumerWidget {
  const AdminsManagementModal({
    super.key,
    this.createChannelFlow = false,
  });

  final bool createChannelFlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAdmins = ref.watch(communityAdminsProvider);
    final communityAdminsPubkeys = useMemoized(communityAdmins.keys.toList, [communityAdmins]);

    final buttonSize = 56.0.s;
    final buttonPaddingTop = 8.0.s;
    final separatorHeight = 16.0.s;
    final height = NavigationAppBar.modalHeaderHeight +
        buttonSize +
        buttonPaddingTop +
        separatorHeight +
        (AdminCard.itemHeight + separatorHeight) * communityAdminsPubkeys.length;

    return SizedBox(
      height: height,
      child: CustomScrollView(
        restorationId: 'admins_management_scroll',
        slivers: [
          SliverAppBar(
            primary: false,
            flexibleSpace: NavigationAppBar.modal(
              showBackButton: false,
              actions: [
                NavigationCloseButton(
                  onPressed: () => context.pop(),
                ),
              ],
              title: Text(context.i18n.channel_create_admins_title),
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: NavigationAppBar.modalHeaderHeight,
            pinned: true,
          ),
          PinnedHeaderSliver(
            child: ScreenSideOffset.small(
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: buttonPaddingTop, bottom: separatorHeight),
                child: Button(
                  mainAxisSize: MainAxisSize.max,
                  minimumSize: Size(buttonSize, buttonSize),
                  leadingIcon: Assets.svg.iconPlusCreatechannel.icon(
                    color: context.theme.appColors.onPrimaryAccent,
                  ),
                  label: Text(
                    context.i18n.channel_create_admins_action,
                  ),
                  onPressed: () {
                    showSimpleBottomSheet<void>(
                      context: context,
                      child: AddAdminModal(createChannelFlow: createChannelFlow),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverList.separated(
            separatorBuilder: (BuildContext _, int __) => SizedBox(height: separatorHeight),
            itemCount: communityAdminsPubkeys.length,
            itemBuilder: (BuildContext context, int index) {
              return ScreenSideOffset.small(
                child: AdminCard(
                  pubkey: communityAdminsPubkeys[index],
                  communityAdminType: communityAdmins[communityAdminsPubkeys[index]]!,
                  createChannelFlow: createChannelFlow,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
