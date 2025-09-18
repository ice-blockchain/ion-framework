// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/protect_account/backup/views/components/backup_option.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/create_recover_key_page/components/cloud_backup_option.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/security_account_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class BackupOptionsPage extends ConsumerWidget {
  const BackupOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;
    final securityMethods = ref.watch(securityAccountControllerProvider).value;

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(locale.protect_account_header_security),
            actions: const [
              NavigationCloseButton(),
            ],
          ),
          SizedBox(height: 16.0.s),
          ScreenSideOffset.small(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.s),
                  child: Column(
                    children: [
                      Text(
                        locale.backup_title,
                        textAlign: TextAlign.center,
                        style: context.theme.appTextThemes.headline2.copyWith(
                          color: context.theme.appColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 8.0.s),
                      Text(
                        locale.backup_description,
                        textAlign: TextAlign.center,
                        style: context.theme.appTextThemes.body2.copyWith(
                          color: context.theme.appColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.0.s),
                const CloudBackupOption(),
                SizedBox(height: 16.0.s),
                BackupOption(
                  title: locale.backup_option_with_recovery_keys_title,
                  subtitle: locale.backup_option_with_recovery_keys_description,
                  icon: Assets.svg.walletLoginRecovery.icon(
                    size: 48.0.s,
                  ),
                  isOptionEnabled: securityMethods?.hasRecoveryKeysEnabled ?? false,
                  onTap: () => BackupRecoveryKeysRoute().push<void>(context),
                ),
                ScreenBottomOffset(margin: 32.0.s),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
