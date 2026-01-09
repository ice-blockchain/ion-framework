// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/sentry/sentry_service.dart';

void reportFailover(Object error, StackTrace stackTrace, {required String tag}) {
  // Sample to avoid flooding Sentry: ~1% of events.
  if (DateTime.now().microsecondsSinceEpoch % 100 != 0) return;

  // Networking must not depend on Sentry availability.
  unawaited(() async {
    try {
      final exception = error is Exception ? error : Exception(error.toString());
      await SentryService.logException(
        exception,
        stackTrace: stackTrace,
        tag: tag,
      );
    } catch (_) {
      // Ignore logging failures.
    }
  }());
}
