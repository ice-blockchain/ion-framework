// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/security_account_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class SecureAccountDialogEvent extends UiEvent {
  const SecureAccountDialogEvent();

  static bool shown = false;

  @override
  void performAction(BuildContext context) {
    if (!shown) {
      shown = true;
      showSimpleBottomSheet<void>(
        context: context,
        isDismissible: false,
        child: const SecureAccountModal(
          isBottomSheet: true,
        ),
      ).whenComplete(() => shown = false);
    }
  }
}

class SecureAccountModal extends ConsumerWidget {
  const SecureAccountModal({
    super.key,
    this.isBottomSheet = false,
  });

  final bool isBottomSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          title: Text(locale.protect_account_header_security),
          showBackButton: false,
          actions: isBottomSheet
              ? null
              : const [
                  NavigationCloseButton(),
                ],
        ),
        SizedBox(height: 16.0.s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.s),
          child: Column(
            children: [
              InfoCard(
                iconAsset: Assets.svg.actionWalletSecureaccount,
                title: locale.protect_account_title_secure_account,
                description: locale.protect_account_description_secure_account,
              ),
              SizedBox(height: 32.0.s),
              Button(
                mainAxisSize: MainAxisSize.max,
                leadingIcon: Assets.svg.iconWalletProtectAccount.icon(
                  color: context.theme.appColors.onPrimaryAccent,
                ),
                label: Text(locale.protect_account_button),
                onPressed: () async {
                  final result = SecureAccountOptionsRoute().push<void>(context);
                  if (isBottomSheet) {
                    await result;
                    final isSecured = await ref.read(isCurrentUserSecuredProvider.future);
                    if (isSecured && context.mounted) {
                      Navigator.of(ref.context).pop();
                    }
                  }
                },
              ),
              ScreenBottomOffset(margin: 36.0.s),
            ],
          ),
        ),
      ],
    );

    return isBottomSheet
        ? SizedBox(
            child: content,
          )
        : SheetContent(
            body: content,
          );
  }
}
