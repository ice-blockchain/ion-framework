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
          TalkerKey.critical: AnsiPen()..xterm(196), // Bright red
          TalkerKey.warning: AnsiPen()..xterm(214), // Golden yellow
          TalkerKey.verbose: AnsiPen()..xterm(244), // Medium gray
          TalkerKey.info: AnsiPen()..xterm(75), // Clear blue
          TalkerKey.debug: AnsiPen()..xterm(242), // Darker gray
          TalkerKey.error: AnsiPen()..xterm(160), // Deep red
          TalkerKey.exception: AnsiPen()..xterm(197), // Bright pink

          // Http section
          TalkerKey.httpError: AnsiPen()..xterm(160), // Deep red
          TalkerKey.httpRequest: AnsiPen()..xterm(69), // Teal
          TalkerKey.httpResponse: AnsiPen()..xterm(71), // Bright green

          // Bloc section
          TalkerKey.blocEvent: AnsiPen()..xterm(68), // Ocean blue
          TalkerKey.blocTransition: AnsiPen()..xterm(140), // Purple
          TalkerKey.blocCreate: AnsiPen()..xterm(72), // Sea green
          TalkerKey.blocClose: AnsiPen()..xterm(161), // Magenta

          // Riverpod section
          TalkerKey.riverpodAdd: AnsiPen()..xterm(67), // Steel blue
          TalkerKey.riverpodUpdate: AnsiPen()..xterm(71), // Bright green
          TalkerKey.riverpodDispose: AnsiPen()..xterm(161), // Magenta
          TalkerKey.riverpodFail: AnsiPen()..xterm(160), // Deep red

          // Flutter section
          TalkerKey.route: AnsiPen()..xterm(140), // Purple
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
