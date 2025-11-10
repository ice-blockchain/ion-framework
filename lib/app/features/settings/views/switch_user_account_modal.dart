// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class SwitchUserAccountModal extends ConsumerWidget {
  const SwitchUserAccountModal({
    required this.selectedUserPubkey,
    super.key,
  });

  final String selectedUserPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              showBackButton: false,
              title: Text(context.i18n.profile_switch_user_header),
              actions: [NavigationCloseButton(onPressed: () => context.pop())],
            ),
            ScreenSideOffset.small(
              child: Column(
                spacing: 16.0.s,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionItem(
                    onTap: () => context.pop(),
                    icon: Assets.svg.iconChannelType
                        .icon(color: context.theme.appColors.primaryAccent),
                    child: Text(
                      'Login with new account',
                      style: context.theme.appTextThemes.body,
                    ),
                  ),
                  // NOTE(ice-linus): Example of how to use the _UserInfo widget with a selected user
                  // Here needs to be a list of delegates for the current user and my own accounts
                  _UserInfo(selectedUserPubkey: selectedUserPubkey, isSelected: true),
                  _UserInfo(selectedUserPubkey: selectedUserPubkey, isSelected: false),
                  _ActionItem(
                    onTap: () => context.pop(),
                    icon: Assets.svg.iconMenuLogout
                        .icon(color: context.theme.appColors.primaryAccent),
                    child: Text(
                      context.i18n.profile_log_out(_getUsername(context, ref)),
                      style: context.theme.appTextThemes.body,
                    ),
                  ),
                ],
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }

  String _getUsername(BuildContext context, WidgetRef ref) {
    final username = ref.watch(
      userPreviewDataProvider(selectedUserPubkey, network: false).select(userPreviewNameSelector),
    );
    return prefixUsername(username: username, context: context);
  }
}

class _ActionItem extends ConsumerWidget {
  const _ActionItem({required this.child, required this.onTap, required this.icon});

  final Widget child;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListItem(
      onTap: onTap,
      leading: Button.icon(
        backgroundColor: context.theme.appColors.secondaryBackground,
        borderColor: context.theme.appColors.onTertiaryFill,
        borderRadius: BorderRadius.all(Radius.circular(10.0.s)),
        size: 36.0.s,
        onPressed: onTap,
        icon: icon,
      ),
      title: child,
      trailing: Assets.svg.iconArrowRight.icon(color: context.theme.appColors.primaryText),
      backgroundColor: context.theme.appColors.tertiaryBackground,
    );
  }
}

class _UserInfo extends ConsumerWidget {
  const _UserInfo({
    required this.selectedUserPubkey,
    required this.isSelected,
  });

  final String selectedUserPubkey;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(selectedUserPubkey, network: false)
          .select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(selectedUserPubkey, network: false).select(userPreviewNameSelector),
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? context.theme.appColors.primaryAccent
            : context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.all(Radius.circular(16.0.s)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
      child: BadgesUserListItem(
        title: Text(
          displayName,
          strutStyle: const StrutStyle(forceStrutHeight: true),
          style: TextStyle(
            color: isSelected
                ? context.theme.appColors.onPrimaryAccent
                : context.theme.appColors.primaryText,
          ),
        ),
        subtitle: Text(
          prefixUsername(username: username, context: context),
          style: TextStyle(
            color: isSelected
                ? context.theme.appColors.onPrimaryAccent
                : context.theme.appColors.tertiaryText,
          ),
        ),
        masterPubkey: selectedUserPubkey,
        contentPadding: EdgeInsets.zero,
        trailing: isSelected ? Assets.svg.iconBlockCheckboxOn.icon() : null,
      ),
    );
  }
}
