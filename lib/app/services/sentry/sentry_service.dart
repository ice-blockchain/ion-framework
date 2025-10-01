// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

mixin SentryService {
  static Future<void> init({
    required ProviderContainer container,
    required AppRunner appRunner,
  }) async {
    // Initialize Sentry only in release mode
    if (!kReleaseMode) {
      appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options
          ..dsn = container.read(envProvider.notifier).get<String>(EnvVariable.SENTRY_DSN)
          ..sendDefaultPii = true
          ..tracesSampleRate = 1.0
          ..profilesSampleRate = 1.0;
      },
      appRunner: appRunner,
    );
  }

  /// Manually log an exception to Sentry
  ///
  /// [exception] - The exception to log
  /// [stackTrace] - Optional stack trace for the exception
  /// [level] - Optional severity level (defaults to SentryLevel.error)
  /// [tag] - Optional tag to categorize the exception
  static Future<SentryId> logException(
    dynamic exception, {
    StackTrace? stackTrace,
    SentryLevel? level,
    String? tag,
  }) async {
    return Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (level != null) {
          scope.level = level;
        }
        if (tag != null) {
          scope.setTag('manual_log', tag);
        }
      },
    );
  }
}
