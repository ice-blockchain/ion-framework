// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TokenAnalyticsLogger implements AnalyticsLogger {
  @override
  void log(String message) {
    Logger.log(message);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    Logger.error(
      error ?? message,
      stackTrace: stackTrace,
      message: error != null ? message : null,
    );
  }
}
