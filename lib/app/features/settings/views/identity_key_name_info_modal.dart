// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/card/rounded_card.dart';
import 'package:ion/app/components/copy/copy_builder.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class IdentityKeyNameInfoModal extends StatelessWidget {
  const IdentityKeyNameInfoModal({
    this.identityKeyName,
    super.key,
  });

  final String? identityKeyName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          title: Text(context.i18n.common_information),
          actions: const [NavigationCloseButton()],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.s),
          child: Column(
            children: [
              InfoCard(
                iconAsset: Assets.svg.actionWalletIdKey,
                title: context.i18n.common_identity_key_name,
                description: context.i18n.settings_identity_key_name_description,
              ),
              if (identityKeyName case final identityKeyName? when identityKeyName.isNotEmpty) ...[
                SizedBox(height: 20.0.s),
                _IdentityKeyNameCard(identityKeyName: identityKeyName),
              ],
              const ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentityKeyNameCard extends StatelessWidget {
  const _IdentityKeyNameCard({required this.identityKeyName});

  final String identityKeyName;

  @override
  Widget build(BuildContext context) {
    final borderColor = context.theme.appColors.onTertiaryFill;

    return CopyBuilder(
      defaultIcon: Assets.svg.iconBlockCopyBlue.icon(
        size: 16.0.s,
        color: context.theme.appColors.primaryAccent,
      ),
      defaultText: context.i18n.button_copy,
      defaultBorderColor: borderColor,
      builder: (context, onCopy, content) => RoundedCard.outlined(
        padding: EdgeInsets.all(16.0.s),
        borderColor: content.borderColor,
        backgroundColor: context.theme.appColors.tertiaryBackground,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                identityKeyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.theme.appTextThemes.subtitle.copyWith(
                  color: context.theme.appColors.primaryText,
                ),
              ),
            ),
            SizedBox(width: 4.0.s),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCopy(identityKeyName),
              child: SizedBox.square(
                dimension: 16.0.s,
                child: content.icon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
