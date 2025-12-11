// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_command/flutter_command.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';

const _verboseRiverpod = false;

class Logger {
  Logger._();

  static Talker? _talker;

  static void init({bool verbose = false}) {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        useConsoleLogs: verbose,
        maxHistoryItems: 100000,
        colors: {
          TalkerLogType.critical.key: AnsiPen()..xterm(196), // Bright red
          TalkerLogType.warning.key: AnsiPen()..xterm(214), // Golden yellow
          TalkerLogType.verbose.key: AnsiPen()..xterm(244), // Medium gray
          TalkerLogType.info.key: AnsiPen()..xterm(75), // Clear blue
          TalkerLogType.debug.key: AnsiPen()..xterm(242), // Darker gray
          TalkerLogType.error.key: AnsiPen()..xterm(160), // Deep red
          TalkerLogType.exception.key: AnsiPen()..xterm(197), // Bright pink

          // Http section
          TalkerLogType.httpError.key: AnsiPen()..xterm(160), // Deep red
          TalkerLogType.httpRequest.key: AnsiPen()..xterm(69), // Teal
          TalkerLogType.httpResponse.key: AnsiPen()..xterm(71), // Bright green

          // Bloc section
          TalkerLogType.blocEvent.key: AnsiPen()..xterm(68), // Ocean blue
          TalkerLogType.blocTransition.key: AnsiPen()..xterm(140), // Purple
          TalkerLogType.blocCreate.key: AnsiPen()..xterm(72), // Sea green
          TalkerLogType.blocClose.key: AnsiPen()..xterm(161), // Magenta

          // Riverpod section
          TalkerLogType.riverpodAdd.key: AnsiPen()..xterm(67), // Steel blue
          TalkerLogType.riverpodUpdate.key: AnsiPen()..xterm(71), // Bright green
          TalkerLogType.riverpodDispose.key: AnsiPen()..xterm(161), // Magenta
          TalkerLogType.riverpodFail.key: AnsiPen()..xterm(160), // Deep red

          // Flutter section
          TalkerLogType.route.key: AnsiPen()..xterm(140), // Purple
        },
      ),
    );

    Command.globalExceptionHandler = (error, stackTrace) {
      _talker?.error('Command error', error, stackTrace);
    };
  }

  static Talker? get talker => _talker;

  static TalkerDioLogger? get talkerDioLogger => TalkerDioLogger(
        talker: talker,
        settings: TalkerDioLoggerSettings(
          requestPen: AnsiPen()..cyan(),
          responsePen: AnsiPen()..green(),
          errorPen: AnsiPen()..red(),
        ),
      );

  static TalkerRiverpodObserver get talkerRiverpodObserver => TalkerRiverpodObserver(
        // enable logger by default + printProviderFailed->true
        settings: const TalkerRiverpodLoggerSettings(
          printProviderAdded: _verboseRiverpod,
          printProviderUpdated: _verboseRiverpod,
          printStateFullData: _verboseRiverpod,
          printFailFullData: _verboseRiverpod,
          printProviderFailed: _verboseRiverpod,
        ),
      );

  static void log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _talker?.log(message);

    if (error != null) {
      _talker?.error(error, stackTrace);
    }
  }

  static void info(String message) {
    _talker?.info(message);
  }

  static void warning(String message) {
    _talker?.warning(message);
  }

  static void error(
    Object error, {
    StackTrace? stackTrace,
    String? message,
  }) {
    _talker?.handle(error, stackTrace, message);
  }
}
