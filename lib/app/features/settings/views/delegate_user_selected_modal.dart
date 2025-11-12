// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class DelegateUserSelectedModal extends ConsumerWidget {
  const DelegateUserSelectedModal({
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
              actions: const [NavigationCloseButton()],
            ),
            ScreenSideOffset.medium(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Assets.svg.actionSettingsDelegate.icon(size: 80.0.s),
                  SizedBox(height: 8.0.s),
                  Text(
                    context.i18n.settings_delegate_access,
                    style: context.theme.appTextThemes.title,
                  ),
                  SizedBox(height: 12.0.s),
                  Text(
                    context.i18n.settings_delegate_access_confirm_user,
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.0.s),
                ],
              ),
            ),
            ScreenSideOffset.small(
              child: Column(
                spacing: 20.0.s,
                children: [
                  _UserInfo(selectedUserPubkey: selectedUserPubkey),
                  Button.compact(
                    onPressed: () => context.pop(true),
                    label: Text(context.i18n.button_confirm),
                    minimumSize: Size(double.infinity, 56.0.s),
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
}

class _UserInfo extends ConsumerWidget {
  const _UserInfo({required this.selectedUserPubkey});

  final String selectedUserPubkey;

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
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.all(Radius.circular(16.0.s)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
      child: Center(
        child: IntrinsicWidth(
          child: BadgesUserListItem(
            title: Text(
              displayName,
              strutStyle: const StrutStyle(forceStrutHeight: true),
              style: TextStyle(
                color: context.theme.appColors.primaryText,
              ),
            ),
            subtitle: Text(
              prefixUsername(username: username, context: context),
              style: TextStyle(
                color: context.theme.appColors.tertiaryText,
              ),
            ),
            masterPubkey: selectedUserPubkey,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
