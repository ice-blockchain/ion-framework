// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class RestrictedRegionUnavailableSheet extends StatelessWidget {
  const RestrictedRegionUnavailableSheet({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          actions: [
            NavigationCloseButton(onPressed: onClose),
          ],
        ),
        ScreenSideOffset.medium(
          child: Column(
            children: [
              InfoCard(
                iconAsset: Assets.svg.actionWalletSwapunavailable,
                title: context.i18n.tokenized_community_restricted_region_unavailable_title,
                description:
                    context.i18n.tokenized_community_restricted_region_unavailable_description,
              ),
              SizedBox(height: 24.0.s),
              Button(
                minimumSize: Size(double.infinity, 56.0.s),
                onPressed: onClose,
                label: Text(context.i18n.button_close),
              ),
            ],
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }
}
