// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/contact_modal_page/components/contact_item.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/balance/contact_actions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({required this.pubkey, super.key});

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;

    if (userPreviewData == null) {
      return const SizedBox.shrink();
    }

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(top: 20.0.s),
                child: ContactItem(userPreviewData: userPreviewData),
              ),
            ],
          ),
          SizedBox(height: 20.0.s),
          ScreenSideOffset.small(
            child: ContactActions(
              onReceive: () => ReceiveCoinRoute().push<void>(context),
              onSend: () {
                ref.invalidate(sendAssetFormControllerProvider);
                ref.read(sendAssetFormControllerProvider.notifier).setContact(pubkey);

                SelectCoinWalletRoute().push<void>(context);
              },
              onNeedToEnable2FA: () => Navigator.of(context).pop(true),
            ),
          ),
          ScreenBottomOffset(margin: 32.0.s),
        ],
      ),
    );
  }
}
