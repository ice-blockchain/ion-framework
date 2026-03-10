// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_identity_client/ion_identity.dart';

Future<void> logWalletApiErrorToSentry(
  Object error, {
  required String tag,
  required String operation,
  required String endpoint,
  String? userAgent,
  StackTrace? stackTrace,
  Map<String, String>? tags,
  Map<String, dynamic>? debugContext,
}) async {
  try {
    final rootError = _unwrapError(error);
    final cause = _extractCause(rootError);
    final sentryTags = <String, String>{
      'wallet_operation': operation,
      'wallet_endpoint': endpoint,
      if (tags != null) ...tags,
    };

    final context = <String, dynamic>{
      'operation': operation,
      'endpoint': endpoint,
      'exceptionType': error.runtimeType.toString(),
      'cause': cause,
      if (userAgent != null) 'userAgent': userAgent,
      ..._extractNetworkContext(rootError),
      ..._extractErrorDebugContext(error),
      if (debugContext != null) ...debugContext,
    };

    await SentryService.logException(
      error,
      stackTrace: stackTrace,
      tag: tag,
      tags: sentryTags,
      debugContext: context,
    );
  } catch (_) {
    // Logging must never break the user flow.
  }
}

Object _unwrapError(Object error) {
  if (error is DebugContextException && error.originalError != null) {
    return error.originalError!;
  }

  return error;
}

Map<String, dynamic> _extractErrorDebugContext(Object error) {
  if (error is DebugContextException) {
    return error.debugContext;
  }

  return const {};
}

Future<Object?> logWalletApiErrorStateTransitionToSentry<T>(
  AsyncValue<T>? previous,
  AsyncValue<T> next, {
  required String tag,
  required String operation,
  required String endpoint,
  String? userAgent,
  Set<Type> excludedErrorTypes = const {},
  bool Function(Object error)? shouldLog,
  Map<String, String>? tags,
  Map<String, dynamic>? debugContext,
}) async {
  if (previous?.isLoading != true || next.isLoading || !next.hasError) {
    return null;
  }

  final error = next.error;
  if (error == null || excludedErrorTypes.contains(error.runtimeType)) {
    return null;
  }
  if (shouldLog != null && !shouldLog(error)) {
    return null;
  }

  await logWalletApiErrorToSentry(
    error,
    stackTrace: next.stackTrace,
    tag: tag,
    operation: operation,
    endpoint: endpoint,
    userAgent: userAgent,
    tags: tags,
    debugContext: debugContext,
  );

  return error;
}

String _extractCause(Object error) {
  if (error is IONException) return error.message;
  if (error is RequestExecutionException) {
    return _extractDioReason(error.error) ?? error.error.toString();
  }
  return _extractDioReason(error) ?? error.toString();
}

Map<String, dynamic> _extractNetworkContext(Object error) {
  final context = <String, dynamic>{};
  final dio = switch (error) {
    RequestExecutionException(error: final nested) when nested is DioException => nested,
    DioException() => error,
    _ => null,
  };

  if (dio == null) {
    return context;
  }

  context['dioType'] = dio.type.name;
  context['requestPath'] = dio.requestOptions.path;
  context['requestMethod'] = dio.requestOptions.method;
  context['statusCode'] = dio.response?.statusCode;

  final apiReason = _extractReasonFromResponse(dio.response?.data);
  if (apiReason != null) context['apiReason'] = apiReason;

  return context;
}

String? _extractDioReason(Object error) {
  if (error is! DioException) return null;
  return _extractReasonFromResponse(error.response?.data) ??
      error.message ??
      error.error?.toString();
}

String? _extractReasonFromResponse(dynamic responseData) {
  if (responseData is String) return _nonEmpty(responseData);
  if (responseData is! Map<String, dynamic>) return null;

  final errorField = responseData['error'];
  final nestedError = errorField is Map<String, dynamic>
      ? _firstNotNull([
          _nonEmpty(errorField['message']?.toString()),
          _nonEmpty(errorField['reason']?.toString()),
        ])
      : null;

  return _firstNotNull([
    _nonEmpty(responseData['reason']?.toString()),
    _nonEmpty(responseData['message']?.toString()),
    nestedError,
  ]);
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

T? _firstNotNull<T>(Iterable<T?> values) {
  for (final value in values) {
    if (value != null) return value;
  }
  return null;
}
