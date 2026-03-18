// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/info_type.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';

class InfoModal extends HookWidget {
  const InfoModal({
    required this.infoType,
    super.key,
  });

  final InfoType infoType;

  // Shows this modal in a bottom sheet with the desired bottom padding.
  static Future<T?> showSheet<T>({
    required BuildContext context,
    required InfoType infoType,
  }) {
    return showSimpleBottomSheet<T>(
      context: context,
      bottomPadding: 16.0.s,
      child: InfoModal(infoType: infoType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = infoType.getDesc(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          title: Text(context.i18n.common_information),
          actions: const [NavigationCloseButton()],
        ),
        SizedBox(
          height: 12.0.s,
        ),
        ScreenSideOffset.small(
          child: InfoCard(
            iconAsset: infoType.iconAsset,
            title: infoType.getTitle(context),
            description: description,
            descriptionTextAlign: TextAlign.start,
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
