// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/auth/views/components/identity_link/identity_link.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

class IdentityInfo extends StatelessWidget {
  const IdentityInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
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
                description: context.i18n.identity_key_name_description,
              ),
              SizedBox(height: 12.0.s),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: context.i18n.identity_key_name_usage),
                    WidgetSpan(child: SizedBox(width: 6.0.s)),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: IdentityLink(),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: context.theme.appTextThemes.body2.copyWith(
                  color: context.theme.appColors.secondaryText,
                ),
              ),
              const ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }
}
