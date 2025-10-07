// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class ContactWalletErrorModal extends StatelessWidget {
  const ContactWalletErrorModal({
    required this.user,
    required this.title,
    required this.iconPath,
    required this.description,
    super.key,
  });

  final String title;
  final String iconPath;
  final String description;
  final UserMetadataEntity user;

  @override
  Widget build(BuildContext context) {
    const textSeparator = TextSpan(text: ' ');

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(start: 29.0.s, end: 28.0.s, top: 30.0.s),
              child: InfoCard(
                iconAsset: iconPath,
                title: title,
                descriptionWidget: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: context.theme.appColors.secondaryText,
                    ),
                    children: [
                      WidgetSpan(
                        child: IonConnectAvatar(
                          size: 20.0.s,
                          masterPubkey: user.masterPubkey,
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      textSeparator,
                      TextSpan(
                        text: user.data.trimmedDisplayName,
                        style: context.theme.appTextThemes.body,
                      ),
                      textSeparator,
                      TextSpan(
                        text: description,
                        style: context.theme.appTextThemes.body2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.0.s),
            ScreenSideOffset.small(
              child: Button(
                label: Text(context.i18n.button_continue),
                mainAxisSize: MainAxisSize.max,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}

Future<void> showContactWalletError(
  BuildContext context, {
  required NetworkData network,
  required UserMetadataEntity user,
  required bool isPrivate,
}) {
  final title = isPrivate
      ? context.i18n.contact_wallet_is_private_title
      : context.i18n.contact_wallet_not_found_title;

  final description = isPrivate
      ? '${context.i18n.contact_wallet_is_private}\n${context.i18n.contact_wallet_is_private_description}'
      : context.i18n.contact_wallet_not_found_description(network.displayName);

  final iconPath =
      isPrivate ? Assets.svg.actionwalletprivatewallet : Assets.svg.actionwalleterrorwallet;

  return showSimpleBottomSheet<void>(
    context: context,
    child: ContactWalletErrorModal(
      user: user,
      title: title,
      iconPath: iconPath,
      description: description,
    ),
  );
}
