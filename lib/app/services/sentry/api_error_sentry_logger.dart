// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion_identity_client/ion_identity.dart';

String extractApiErrorCause(Object error) {
  if (error is IONException) return error.message;
  if (error is RequestExecutionException) {
    return extractApiErrorDioReason(error.error) ?? error.error.toString();
  }
  return extractApiErrorDioReason(error) ?? error.toString();
}

Map<String, dynamic> extractApiErrorNetworkContext(Object error) {
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

  final apiReason = extractApiErrorReasonFromResponse(dio.response?.data);
  if (apiReason != null) context['apiReason'] = apiReason;

  return context;
}

String? extractApiErrorDioReason(Object error) {
  if (error is! DioException) return null;
  return extractApiErrorReasonFromResponse(error.response?.data) ??
      error.message ??
      error.error?.toString();
}

String? extractApiErrorReasonFromResponse(dynamic responseData) {
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
