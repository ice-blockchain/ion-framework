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

enum TokenCreationNotAvailableModalType {
  comments,
  noDefinition;

  String description(BuildContext context) => switch (this) {
        comments => context.i18n.tokenized_community_not_available_comments_description,
        noDefinition => context.i18n.tokenized_community_not_available_no_definition_description,
      };
}

class TokenCreationNotAvailableModal extends StatelessWidget {
  const TokenCreationNotAvailableModal({
    required this.type,
    super.key,
  });

  final TokenCreationNotAvailableModalType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          actions: const [NavigationCloseButton()],
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(28.s, 0.s, 28.s, 26.s),
          child: InfoCard(
            iconAsset: Assets.svg.walletIconFeedCantcreatetoken,
            title: context.i18n.tokenized_community_not_available_title,
            description: type.description(context),
          ),
        ),
        ScreenSideOffset.small(
          child: Button(
            label: Text(context.i18n.button_close),
            mainAxisSize: MainAxisSize.max,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }
}
