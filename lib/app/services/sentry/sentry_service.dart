// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

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
          ..beforeSend = _filterEvents
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
  /// [debugContext] - Optional map of additional context data for debugging
  static Future<SentryId> logException(
    dynamic exception, {
    StackTrace? stackTrace,
    SentryLevel? level,
    String? tag,
    Map<String, dynamic>? debugContext,
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
        if (debugContext != null) {
          scope.setContexts('debug_context', debugContext);
        }
      },
    );
  }

  /// Callback for filtering events before sending to Sentry
  ///
  /// Returns the event if it should be sent, or null to drop it
  static SentryEvent? _filterEvents(SentryEvent event, Hint hint) {
    // Always allow manually logged events through
    if (event.tags?.containsKey('manual_log') ?? false) {
      return event;
    }

    // Filter out network connectivity issues (not client/server errors)
    if (_isNetworkConnectivityIssue(event, hint)) {
      return null; // Drop the event
    }
    return event;
  }

  static const List<String> _connectivityErrorReasons = [
    'failed host lookup',
    'connection terminated',
    'network is unreachable',
    'connection refused',
    'connection timed out',
    'connection closed',
    'software caused connection abort',
    'broken pipe',
    'no route to host',
    // TLS handshake transient failures
    'bad_decrypt',
    'decryption_failed_or_bad_record_mac',
    'tlsv1_alert_decode_error',
  ];

  static const List<String> _httpConnectivityErrorReasons = [
    'connection closed before',
    'connection terminated',
  ];

  static const List<String> _clientExceptionConnectivityReasons = [
    'connection closed',
    'software caused connection abort',
    'connection failed',
    'connection refused',
    'connection timed out',
    'connection aborted',
    'timeout occurred',
    'request timeout',
    'network timeout',
    'socket timeout',
    'connection timeout',
    'read timeout',
    'write timeout',
  ];

  /// Checks if an event is a network connectivity issue (not a client/server error)
  ///
  /// Returns true for network issues like:
  /// - Connection timeouts
  /// - Connection refused
  /// - Network unreachable
  /// - Connection lost during request
  /// - SSL/TLS handshake failures
  ///
  /// Returns false for:
  /// - HTTP client errors (4xx status codes)
  /// - HTTP server errors (5xx status codes)
  static bool _isNetworkConnectivityIssue(SentryEvent event, Hint hint) {
    // Check the throwable from hint first (most reliable)
    final throwable = hint.get('exception');
    // Check for common network connectivity exceptions
    if (throwable is SocketException) {
      // Allow client/server errors through
      // SocketException with specific status codes should be reported
      final message = throwable.message.toLowerCase();

      // Filter out connectivity issues
      if (_connectivityErrorReasons.any(message.contains)) {
        return true;
      }
    }

    if (throwable is HandshakeException) {
      final message = throwable.message.toLowerCase();

      // Filter out connectivity issues
      if (_connectivityErrorReasons.any(message.contains)) {
        return true;
      }
    }

    if (throwable is HttpException) {
      final message = throwable.message.toLowerCase();

      // Filter out connectivity issues, not HTTP status code errors
      if (_httpConnectivityErrorReasons.any(message.contains)) {
        return true;
      }

      // Let HTTP status code errors (4xx, 5xx) pass through
      return false;
    }

    // Handle ClientException from http package
    if (throwable.runtimeType.toString().toLowerCase().contains('clientexception')) {
      final message = throwable.toString().toLowerCase();

      // Filter out connectivity issues, not status codes
      if (_clientExceptionConnectivityReasons.any(message.contains)) {
        return true;
      }

      // Let HTTP status code errors pass through
      return false;
    }

    // Check exception types from the event
    final exceptions = event.exceptions;
    if (exceptions != null && exceptions.isNotEmpty) {
      for (final exception in exceptions) {
        final type = exception.type?.toLowerCase() ?? '';
        final value = exception.value?.toLowerCase() ?? '';

        // Filter network connectivity exceptions
        if (type.contains('socketexception') ||
            type.contains('handshakeexception') ||
            type.contains('dioexception')) {
          // Check if it's a connectivity issue, not a status code error
          if (_connectivityErrorReasons.any(value.contains)) {
            return true;
          }
        }

        // Filter HttpException connectivity issues
        if (type.contains('httpexception')) {
          if (_httpConnectivityErrorReasons.any(value.contains)) {
            return true;
          }
          // Let HTTP status code errors (4xx, 5xx) pass through
        }

        // Filter ClientException from http package (but check for status codes)
        if (type.contains('clientexception')) {
          // Only filter if it's about connection, not status codes
          if (_clientExceptionConnectivityReasons.any(value.contains)) {
            return true;
          }
        }
      }
    }

    return false;
  }
}
