// SPDX-License-Identifier: ice License 1.0

import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header_icon.dart';
import 'package:ion/app/features/protect_account/authenticator/data/model/authenticator_type.dart';
import 'package:ion/app/features/protect_account/components/secure_account_option.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/show_close_button_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class AuthenticatorSetupOptionsPage extends ConsumerWidget {
  const AuthenticatorSetupOptionsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const authenticatorTypes = AuthenticatorType.values;

    return SheetContent(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            primary: false,
            flexibleSpace: NavigationAppBar.modal(
              showCloseButton: ref.watch(showCloseButtonProvider),
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: NavigationAppBar.modalHeaderHeight,
            pinned: true,
          ),
          SliverFillRemaining(
            child: Column(
              children: [
                AuthHeader(
                  title: context.i18n.authenticator_setup_title,
                  description: context.i18n.authenticator_setup_description,
                  titleStyle: context.theme.appTextThemes.headline2,
                  descriptionStyle: context.theme.appTextThemes.body2.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                  icon: AuthHeaderIcon(
                    icon: Assets.svg.icon2faAuthsetup.icon(size: 36.0.s),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: 32.0.s),
                      Expanded(
                        child: ListView.builder(
                          itemCount: authenticatorTypes.length,
                          itemBuilder: (context, index) {
                            final type = authenticatorTypes[index];

                            return ScreenSideOffset.small(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(bottom: 12.0.s),
                                child: SecureAccountOption(
                                  isEnabled: false,
                                  title: type.getDisplayName(context),
                                  icon: type.iconAsset.icon(),
                                  onTap: () => _onOptionTap(type),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const HorizontalSeparator(),
                SizedBox(height: 12.0.s),
                ScreenSideOffset.large(
                  child: Button(
                    mainAxisSize: MainAxisSize.max,
                    label: Text(context.i18n.button_next),
                    onPressed: () => AuthenticatorSetupInstructionsRoute().push<void>(context),
                  ),
                ),
                ScreenBottomOffset(margin: 36.0.s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onOptionTap(AuthenticatorType type) async {
    await LaunchApp.openApp(
      androidPackageName: type.androidPackageName,
      iosUrlScheme: type.iosAppUrlScheme,
      appStoreLink: type.appStoreLink,
    );
  }
}
