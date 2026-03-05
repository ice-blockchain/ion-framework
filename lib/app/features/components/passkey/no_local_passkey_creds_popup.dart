// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class NoLocalPasskeyCredsPopup extends StatelessWidget {
  const NoLocalPasskeyCredsPopup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final minSize = Size(56.0.s, 56.0.s);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 30.0.s),
          child: InfoCard(
            iconAsset: Assets.svg.actionLoginLinkaccount,
            title: context.i18n.error_identity_no_local_passkey_creds_found_title,
            description: context.i18n.error_identity_no_local_passkey_creds_found_description,
          ),
        ),
        SizedBox(height: 38.0.s),
        ScreenSideOffset.small(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Button.compact(
                  type: ButtonType.outlined,
                  label: Text(context.i18n.button_cancel),
                  minimumSize: minSize,
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ),
              SizedBox(
                width: 16.0.s,
              ),
              Expanded(
                child: Button.compact(
                  label: Text(context.i18n.button_continue),
                  minimumSize: minSize,
                  onPressed: () async {
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
            ],
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
