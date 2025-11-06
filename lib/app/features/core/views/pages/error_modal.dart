// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/exception_presenter_provider.r.dart';
import 'package:ion/app/features/core/views/pages/error_modal/error_modal_body.dart';
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

    return ErrorModalBody(
      title: exceptionPresentation.title,
      description: exceptionPresentation.description,
      iconAsset: exceptionPresentation.iconPath,
    );
  }
}

void showErrorModal(BuildContext context, Object error) {
  showSimpleBottomSheet<void>(
    context: context,
    child: ErrorModal(error: error),
  );
}
