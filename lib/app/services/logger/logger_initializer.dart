// SPDX-License-Identifier: ice License 1.0

import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

class LoggerInitializer {
  LoggerInitializer._();

  static void initialize(ProviderContainer container) {
    final logApp = container.read(featureFlagsProvider.notifier).get(LoggerFeatureFlag.logApp);

    // if (logApp) {
    Logger.init(verbose: true);
    // }

    // Handles Flutter-specific errors and exceptions
    FlutterError.onError = (errorDetails) {
      Logger.error(
        errorDetails.exception,
        stackTrace: errorDetails.stack,
        message: '[Flutter Error] ${errorDetails.exceptionAsString()}',
      );
    };

    // Handles platform-level errors that occur outside of the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      // Ignore expected cancellation errors
      if (error is StateError && error.message == 'cancelled') {
        return true; // Silently handle it
      }

      Logger.error('[Platform Error] $error', stackTrace: stack);
      return true;
    };

    // Sets up an error listener for the current isolate
    Isolate.current.addErrorListener(
      RawReceivePort((List<dynamic> pair) async {
        final errorAndStacktrace = pair;
        Logger.error(
          '[Isolate Error] ${errorAndStacktrace.first}',
          stackTrace: errorAndStacktrace.last as StackTrace?,
        );
      }).sendPort,
    );
  }
}
