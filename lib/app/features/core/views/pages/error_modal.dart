// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/exception_presenter_provider.r.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/logger/logger.dart';

class ErrorModal extends ConsumerWidget {
  ErrorModal({required this.error, super.key}) {
    Logger.error(error);
  }

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exceptionPresenter = ref.watch(exceptionPresenterProvider);
    final exceptionPresentation = exceptionPresenter.getPresentation(context, error);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 30.0.s),
              child: InfoCard(
                title: exceptionPresentation.title,
                description: exceptionPresentation.description,
                iconAsset: exceptionPresentation.iconPath,
              ),
            ),
            SizedBox(height: 24.0.s),
            ScreenSideOffset.small(
              child: Button(
                label: Text(context.i18n.button_try_again),
                mainAxisSize: MainAxisSize.max,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}

void showErrorModal(BuildContext context, Object error) {
  showSimpleBottomSheet<void>(
    context: context,
    child: ErrorModal(error: error),
  );
}
