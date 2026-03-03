// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header_icon.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class SettingsRedirectSheet extends StatelessWidget {
  const SettingsRedirectSheet({
    required this.header,
    required this.title,
    required this.description,
    required this.headerIconAsset,
    required this.iconAsset,
    super.key,
  });

  factory SettingsRedirectSheet.fromType(
    BuildContext context,
    Permission permissionType,
  ) {
    return switch (permissionType) {
      Permission.photos => SettingsRedirectSheet(
          header: context.i18n.gallery_permission_headline,
          title: context.i18n.gallery_no_access_title,
          description: context.i18n.common_no_access_permission,
          headerIconAsset: Assets.svg.iconPostGallerypermission,
          iconAsset: Assets.svg.walletIconWalletNoaccess,
        ),
      Permission.camera => SettingsRedirectSheet(
          header: context.i18n.camera_permission_headline,
          title: context.i18n.camera_no_access_title,
          description: context.i18n.common_no_access_permission,
          headerIconAsset: Assets.svg.iconPostCamerapermission,
          iconAsset: Assets.svg.walletIconWalletNoaccesscamera,
        ),
      Permission.notifications => SettingsRedirectSheet(
          header: context.i18n.push_notifications_permission_headline,
          title: context.i18n.push_notifications_no_access_title,
          description: context.i18n.push_notifications_no_access_description,
          headerIconAsset: Assets.svg.iconProfileNotifications,
          iconAsset: Assets.svg.walletIconProfileDisablednotification,
        ),
      _ => throw Exception(
          'UI is not implemented for the permission type $permissionType',
        ),
    };
  }

  final String header;
  final String title;
  final String description;
  final String iconAsset;
  final String headerIconAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            leading: NavigationCloseButton(
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          AuthHeader(
            title: header,
            titleStyle: context.theme.appTextThemes.headline2,
            icon: AuthHeaderIcon(
              icon: headerIconAsset.icon(size: 36.0.s),
            ),
          ),
          const Spacer(),
          ScreenSideOffset.medium(
            child: InfoCard(
              iconAsset: iconAsset,
              title: title,
              description: description,
            ),
          ),
          const Spacer(),
          ScreenSideOffset.large(
            child: Button(
              mainAxisSize: MainAxisSize.max,
              label: Text(context.i18n.button_go_to_settings),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
          const ScreenBottomOffset(),
        ],
      ),
    );
  }
}
