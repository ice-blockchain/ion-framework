// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/upload_limit_modal_type.dart';
import 'package:ion/generated/assets.gen.dart';

class UploadLimitReachedModal extends StatelessWidget {
  const UploadLimitReachedModal({
    required this.type,
    super.key,
  });

  final UploadLimitModalType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding:
              EdgeInsetsDirectional.only(start: 28.0.s, end: 28.0.s, top: 38.0.s, bottom: 31.0.s),
          child: InfoCard(
            iconAsset: Assets.svg.actionWalletKeyserror,
            title: context.i18n.upload_limit_error_title,
            description: type.getDescription(context),
          ),
        ),
        ScreenSideOffset.small(
          child: Button(
            label: Text(context.i18n.button_try_again),
            mainAxisSize: MainAxisSize.max,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
