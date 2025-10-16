// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/report_user_modal/components/report_option_selector.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/report_user_modal/report_sent_modal.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/report_user_modal/types/report_reason_type.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class ReportUserModal extends HookConsumerWidget {
  const ReportUserModal({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(
        userPreviewDataProvider(pubkey).select((value) => value.valueOrNull?.data.name ?? ''));
    final formKey = useRef(GlobalKey<FormState>());
    final reportReason = useState<ReportReasonType?>(null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 30.0.s),
          child: InfoCard(
            iconAsset: Assets.svg.actionProfileBlockuser,
            title: context.i18n.profile_popup_report_title(name),
            description: context.i18n.profile_popup_report_desc,
          ),
        ),
        SizedBox(height: 26.0.s),
        ScreenSideOffset.large(
          child: Form(
            key: formKey.value,
            child: Column(
              children: [
                ReportOptionSelector(
                  onSaved: (value) {
                    reportReason.value = value;
                  },
                ),
                SizedBox(height: 21.0.s),
                Button(
                  onPressed: () {
                    if (formKey.value.currentState!.validate()) {
                      rootNavigatorKey.currentState?.pop();
                      showSimpleBottomSheet<void>(
                        context: context,
                        child: const ReportSentModal(),
                      );
                    }
                  },
                  label: Text(context.i18n.button_report),
                  mainAxisSize: MainAxisSize.max,
                ),
              ],
            ),
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }
}
