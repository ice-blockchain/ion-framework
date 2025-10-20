// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/modal_sheets/simple_modal_sheet.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class ConfirmLogoutModal extends ConsumerWidget {
  const ConfirmLogoutModal({required this.pubkey, super.key});

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    final username = prefixUsername(
      context: context,
      username: userPreviewData!.data.name,
    );

    final buttonMinimalSize = Size(56.0.s, 56.0.s);

    return SimpleModalSheet.alert(
      iconAsset: Assets.svg.actionCreatepostLogout,
      title: context.i18n.confirm_logout_title(username),
      description: context.i18n.confirm_logout_description,
      button: ScreenSideOffset.small(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Button.compact(
                type: ButtonType.outlined,
                label: Text(context.i18n.button_cancel),
                onPressed: context.pop,
                minimumSize: buttonMinimalSize,
              ),
            ),
            SizedBox(width: 15.0.s),
            Expanded(
              child: Button.compact(
                label: Text(context.i18n.button_log_out),
                onPressed: ref.read(authProvider.notifier).signOut,
                minimumSize: buttonMinimalSize,
                backgroundColor: context.theme.appColors.attentionRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
