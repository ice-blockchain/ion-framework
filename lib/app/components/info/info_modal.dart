// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/info/info_type.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class InfoModal extends HookWidget {
  const InfoModal({
    required this.infoType,
    super.key,
  });

  final InfoType infoType;

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
          height: 16.0.s,
        ),
        ScreenSideOffset.medium(
          child: InfoCard(
            iconAsset: infoType.iconAsset,
            title: infoType.getTitle(context),
            description: description,
          ),
        ),
        ScreenBottomOffset(margin: 16.0.s),
      ],
    );
  }
}
