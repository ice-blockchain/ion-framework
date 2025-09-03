// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_auth_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

class IonConnectLogger implements NostrDartLogger {
  static const _prefix = '🚀 NETWORK_CALL:';

  @override
  bool get incomingMessageLoggingEnabled => true;

  @override
  bool get outgoingMessageLoggingEnabled => true;

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.info('$_prefix $message');

    if (error != null) {
      Logger.error('$_prefix $error', stackTrace: stackTrace);
    }
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (RelayAuthService.isRelayAuthError(error)) {
      // suppress expected relay error during a relay authentication to reduce the noise in the logs
      return;
    }

    Logger.warning('$_prefix $message');

    if (error != null) {
      Logger.error('$_prefix $error', stackTrace: stackTrace);
    }
  }
}
