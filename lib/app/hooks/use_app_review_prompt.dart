// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/app_review/app_review_modal.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/review/app_review_controller.r.dart';

void useAppReviewPrompt(WidgetRef ref) {
  final context = useContext();

  useEffect(
    () {
      final timer = Timer(const Duration(seconds: 5), () async {
        final controller = ref.read(appReviewControllerProvider.notifier);

        if (await controller.shouldShowReview()) {
          if (!context.mounted) return;

          unawaited(
            showSimpleBottomSheet(
              context: context,
              isDismissible: false,
              child: const AppReviewModal(),
            ),
          );
        }
      });

      return timer.cancel;
    },
    [],
  );
}
