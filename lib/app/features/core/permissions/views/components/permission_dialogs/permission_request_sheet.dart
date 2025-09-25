// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/providers/app_info_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class PermissionRequestSheet extends ConsumerWidget {
  const PermissionRequestSheet({
    required this.permission,
    super.key,
  });

  final Permission permission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appInfoProvider).value?.appName ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 42.0.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.s),
          child: switch (permission) {
            Permission.photos => InfoCard(
                title: context.i18n.photo_library_require_access_title(appName),
                description: context.i18n.photo_library_require_access_description,
                iconAsset: Assets.svg.walletIconWalletGelleryperm,
              ),
            Permission.camera => InfoCard(
                title: context.i18n.camera_require_access_title(appName),
                description: context.i18n.camera_require_access_description,
                iconAsset: Assets.svg.walletIconWalletCamera,
              ),
            Permission.notifications => InfoCard(
                title: context.i18n.push_notifications_require_access_title(appName),
                description: context.i18n.push_notifications_require_access_description,
                iconAsset: Assets.svg.walletIconWalletCamera,
              ),
            _ => throw Exception(
                'UI is not implemented for the permission type $permission',
              ),
          },
        ),
        SizedBox(height: 32.0.s),
        ScreenSideOffset.small(
          child: Button(
            mainAxisSize: MainAxisSize.max,
            label: Text(context.i18n.button_continue),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }
}
