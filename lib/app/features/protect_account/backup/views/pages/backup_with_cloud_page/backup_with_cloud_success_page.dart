// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/protect_account/hooks/use_go_to_secure_account_options.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class BackupWithCloudSuccessPage extends HookConsumerWidget {
  const BackupWithCloudSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goToSecureAccountOptions = usePopToSecureAccountOptions(ref);

    return SheetContent(
      body: Padding(
        padding: EdgeInsetsDirectional.only(top: 45.0.s, bottom: 16.0.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScreenSideOffset.medium(
              child: InfoCard(
                iconAsset: Assets.svg.actionWalletSecureaccsuccess,
                title: context.i18n.backup_cloud_success_title,
                description: context.i18n.backup_cloud_success_description(
                  Platform.isIOS ? context.i18n.backup_icloud : context.i18n.backup_google_drive,
                ),
              ),
            ),
            SizedBox(
              height: 22.0.s,
            ),
            ScreenSideOffset.large(
              child: Button(
                mainAxisSize: MainAxisSize.max,
                label: Text(
                  context.i18n.button_back_to_security,
                ),
                onPressed: goToSecureAccountOptions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
