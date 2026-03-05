// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class ReportSentModal extends ConsumerWidget {
  const ReportSentModal({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 79.0.s),
          child: InfoCard(
            iconAsset: Assets.svg.walletIconWalletReport,
            title: context.i18n.profile_popup_report_success_title,
            description: context.i18n.profile_popup_report_success_desc,
          ),
        ),
        SizedBox(height: 57.0.s),
        ScreenSideOffset.large(
          child: Button(
            onPressed: () {
              rootNavigatorKey.currentState?.pop();
            },
            label: Text(context.i18n.button_close),
            mainAxisSize: MainAxisSize.max,
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
