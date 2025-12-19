// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class AdsModalPage extends HookConsumerWidget {
  const AdsModalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              showBackButton: false,
              title: Text(context.i18n.ads_modal_title),
              actions: const [
                NavigationCloseButton(),
              ],
            ),
            SizedBox(height: 16.0.s),
            ScreenSideOffset.small(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Assets.svg.actionInformationAds.iconWithDimensions(
                    width: 80.0.s,
                    height: 80.0.s,
                  ),
                  SizedBox(height: 10.0.s),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.i18n.ads_modal_subtitle,
                        style: textStyles.title.copyWith(
                          color: colors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.0.s),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: context.i18n.ads_modal_description_part_1,
                              style: textStyles.body2.copyWith(
                                color: colors.secondaryText,
                              ),
                            ),
                            TextSpan(
                              text: context.i18n.ads_modal_description_part_2,
                              style: textStyles.body2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.secondaryText,
                              ),
                            ),
                            TextSpan(
                              text: context.i18n.ads_modal_description_part_3,
                              style: textStyles.body2.copyWith(
                                color: colors.secondaryText,
                              ),
                            ),
                            TextSpan(
                              text: context.i18n.ads_modal_description_part_4,
                              style: textStyles.body2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.secondaryText,
                              ),
                            ),
                            TextSpan(
                              text: context.i18n.ads_modal_description_part_5,
                              style: textStyles.body2.copyWith(
                                color: colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0.s),
            ScreenSideOffset.small(
              child: Button(
                onPressed: () {
                  AdsBenefitsRoute().push<void>(context);
                },
                label: Text(
                  context.i18n.ads_modal_learn_more,
                  style: textStyles.body.copyWith(
                    color: colors.onPrimaryAccent,
                  ),
                ),
                backgroundColor: colors.primaryAccent,
                borderRadius: BorderRadius.circular(16.0.s),
                minimumSize: Size(double.infinity, 56.0.s),
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
