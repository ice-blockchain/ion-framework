// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

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

  @override
  void logHttpRequest(String method, String url, Object? data) {
    var dataString = '';
    if (data != null) {
      try {
        if (data is String) {
          dataString = data.isEmpty ? '""' : data;
        } else {
          dataString = const JsonEncoder.withIndent('  ').convert(data);
        }
      } catch (e) {
        dataString = '[Unable to format request: $e]';
      }
    } else {
      dataString = '""';
    }

    final buffer = StringBuffer()..writeln('[http-request] [$method] $url');

    // Format data with proper indentation (matching Dio format)
    if (dataString.contains('\n')) {
      final lines = dataString.split('\n');
      buffer.writeln('Data: ${lines.first}');
      for (final line in lines.skip(1)) {
        buffer.writeln(line);
      }
    } else {
      buffer.writeln('Data: $dataString');
    }

    Logger.log(buffer.toString().trimRight());
  }

  @override
  void logHttpResponse(String method, String url, int? statusCode, Object? data) {
    final status = statusCode ?? 0;
    final statusMessage = _getStatusMessage(status);

    var dataString = '';
    if (data != null) {
      try {
        if (data is String) {
          dataString = data.isEmpty ? '""' : data;
        } else {
          dataString = const JsonEncoder.withIndent('  ').convert(data);
        }
      } catch (e) {
        dataString = '[Unable to format response: $e]';
      }
    } else {
      dataString = '""';
    }

    final buffer = StringBuffer()
      ..writeln('[http-response] [$method] $url')
      ..writeln('Status: $status')
      ..writeln('Message: $statusMessage');

    // Format data with proper indentation (matching Dio format)
    if (dataString.contains('\n')) {
      final lines = dataString.split('\n');
      buffer.writeln('Data: ${lines.first}');
      for (final line in lines.skip(1)) {
        buffer.writeln(line);
      }
    } else {
      buffer.writeln('Data: $dataString');
    }

    Logger.log(buffer.toString().trimRight());
  }

  @override
  void logHttpError(String method, String url, Object error, StackTrace stackTrace) {
    final buffer = StringBuffer()
      ..writeln('HTTP/2 Error')
      ..writeln('[$method] $url')
      ..writeln('Error: $error');

    Logger.error(
      error,
      stackTrace: stackTrace,
      message: buffer.toString().trimRight(),
    );
  }

  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 202:
        return 'Accepted';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return 'Unknown';
    }
  }
}
