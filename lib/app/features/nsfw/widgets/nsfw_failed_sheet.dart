// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/error_modal/error_modal_body.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class NsfwFailedSheet extends StatelessWidget {
  const NsfwFailedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorModalBody(
      title: context.i18n.error_general_title,
      description: context.i18n.error_general_description(''),
      iconAsset: Assets.svg.actionWalletKeyserror,
    );
  }
}

void showNsfwFailedSheet(BuildContext context) {
  showSimpleBottomSheet<void>(
    context: context,
    child: const NsfwFailedSheet(),
  );
}
