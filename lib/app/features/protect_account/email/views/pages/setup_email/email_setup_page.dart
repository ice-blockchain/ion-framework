// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header_icon.dart';
import 'package:ion/app/features/protect_account/email/data/model/email_steps.dart';
import 'package:ion/app/features/protect_account/email/views/pages/setup_email/step_pages.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/show_close_button_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class EmailSetupPage extends ConsumerWidget {
  const EmailSetupPage(this.step, this.email, {super.key});

  final EmailSetupSteps step;
  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: step == EmailSetupSteps.success
          ? Padding(
              padding: EdgeInsetsDirectional.only(top: 45.0.s, bottom: 16.0.s),
              child: const EmailSetupSuccessPage(),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  primary: false,
                  flexibleSpace: NavigationAppBar.modal(
                    showBackButton: step != EmailSetupSteps.success,
                    showCloseButton:
                        step != EmailSetupSteps.success && ref.watch(showCloseButtonProvider),
                  ),
                  toolbarHeight: NavigationAppBar.modalHeaderHeight,
                  automaticallyImplyLeading: false,
                  pinned: true,
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      AuthHeader(
                        topOffset: 34.0.s,
                        title: step.getPageTitle(context),
                        description: step.getDescription(context),
                        titleStyle: context.theme.appTextThemes.headline2,
                        descriptionStyle: context.theme.appTextThemes.body2.copyWith(
                          color: context.theme.appColors.secondaryText,
                        ),
                        icon: AuthHeaderIcon(
                          icon: Assets.svg.icon2faEmailauth.icon(size: 36.0.s),
                        ),
                      ),
                      if (step == EmailSetupSteps.input)
                        const Expanded(
                          child: EmailSetupInputPage(),
                        ),
                      if (step == EmailSetupSteps.confirmation)
                        Expanded(
                          child: EmailSetupConfirmPage(email: email!),
                        ),
                      ScreenBottomOffset(margin: 36.0.s),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
