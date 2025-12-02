// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/modal_action_button/modal_action_button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/components/accounts_list/accounts_list.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/switch_account_modal_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class SwitchAccountModal extends HookConsumerWidget {
  const SwitchAccountModal({
    super.key,
    this.enableAccountManagement = true,
  });

  final bool enableAccountManagement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadataValue = ref.watch(currentUserMetadataProvider).valueOrNull;
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    return SheetContent(
      body: ScreenSideOffset.small(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16.0.s,
            children: [
              NavigationAppBar.modal(
                showBackButton: false,
                title: Text(context.i18n.profile_switch_user_header),
                actions: const [NavigationCloseButton()],
              ),
              if (enableAccountManagement)
                ModalActionButton(
                  icon: Assets.svg.iconChannelType.icon(
                    color: context.theme.appColors.primaryAccent,
                  ),
                  label: context.i18n.profile_create_new_account,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(switchAccountModalNotifierProvider.notifier)
                        .clearCurrentUserForAuthentication();
                  },
                ),
              SwitchAccountModalList(
                onSelectUser: () {
                  if (enableAccountManagement) {
                    Navigator.of(context).pop();
                    FeedRoute().go(context);
                  }
                },
              ),
              if (enableAccountManagement && currentPubkey != null)
                ModalActionButton(
                  icon: Assets.svg.iconMenuLogout.icon(size: 24.0.s),
                  label: context.i18n.profile_log_out(
                    prefixUsername(username: userMetadataValue?.data.name, context: context),
                  ),
                  onTap: () => ConfirmLogoutRoute(pubkey: currentPubkey).push<void>(context),
                ),
              ScreenBottomOffset(margin: 32.0.s),
            ],
          ),
        ),
      ),
    );
  }
}
