// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/wallets/views/pages/contact_modal_page/components/contact_item_avatar.dart';
import 'package:ion/app/features/wallets/views/pages/contact_modal_page/components/contact_item_name.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class ContactItem extends StatelessWidget {
  const ContactItem({
    required this.userPreviewData,
    super.key,
  });

  final UserPreviewEntity userPreviewData;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        context.pop();
        await ProfileRoute(pubkey: userPreviewData.masterPubkey).push<void>(context);
        final rootContext = rootNavigatorKey.currentContext;
        if (rootContext != null && rootContext.mounted) {
          await ContactRoute(pubkey: userPreviewData.masterPubkey).push<void>(rootContext);
        }
      },
      child: Column(
        children: [
          ContactItemAvatar(pubkey: userPreviewData.masterPubkey),
          SizedBox(height: 8.0.s),
          ContactItemName(userPreviewData: userPreviewData),
          SizedBox(height: 4.0.s),
          Text(
            prefixUsername(username: userPreviewData.data.name, context: context),
            style: context.theme.appTextThemes.caption
                .copyWith(color: context.theme.appColors.tertiaryText),
          ),
        ],
      ),
    );
  }
}
