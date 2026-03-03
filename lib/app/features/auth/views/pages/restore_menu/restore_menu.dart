// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/pages/restore_menu/restore_menu_item.dart';
import 'package:ion/app/features/protect_account/backup/providers/cloud_stored_recovery_keys_names_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class RestoreMenuPage extends ConsumerWidget {
  const RestoreMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloudType =
        Platform.isIOS ? context.i18n.backup_icloud : context.i18n.backup_google_drive;
    final descriptionCloudType = Platform.isIOS
        ? context.i18n.restore_from_cloud_description_type_icloud
        : context.i18n.restore_from_cloud_description_type_google_drive;

    return SheetContent(
      body: AuthScrollContainer(
        title: context.i18n.restore_identity_title,
        description: context.i18n.restore_identity_type_description,
        icon: Assets.svg.iconLoginRestorekey.icon(size: 36.0.s),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 38.0.s),
            child: Column(
              children: [
                SizedBox(height: 12.0.s),
                RestoreMenuItem(
                  icon: Assets.svg.walletLoginCloud.icon(size: 48.0.s),
                  title: context.i18n.restore_identity_from(cloudType),
                  description: context.i18n.restore_from_cloud_description(descriptionCloudType),
                  onPressed: () async {
                    final availableKeys =
                        await ref.watch(cloudStoredRecoveryKeysNamesProvider.future);
                    if (!context.mounted) return;
                    if (availableKeys.isEmpty) {
                      await RestoreFromCloudNoKeysRoute().push<void>(context);
                    } else {
                      await RestoreFromCloudRoute().push<void>(context);
                    }
                  },
                ),
                SizedBox(height: 16.0.s),
                RestoreMenuItem(
                  icon: Assets.svg.walletLoginRecovery.icon(size: 48.0.s),
                  title: context.i18n.restore_identity_type_credentials_title,
                  description: context.i18n.restore_identity_type_credentials_description,
                  onPressed: () => RecoverUserRoute().push<void>(context),
                ),
                SizedBox(height: 12.0.s),
              ],
            ),
          ),
          const ScreenBottomOffset(child: AuthFooter()),
        ],
      ),
    );
  }
}
