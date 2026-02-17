// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ion_identity_client/src/core/network/network_exception.dart';
import 'package:ion_identity_client/src/core/types/ion_exception.dart';

class RestrictedRegionErrorData {
  const RestrictedRegionErrorData({
    required this.message,
    this.country,
    this.city,
    this.region,
    this.regionCode,
  });

  final String message;
  final String? country;
  final String? city;
  final String? region;
  final String? regionCode;
}

class RestrictedRegionErrorParser {
  const RestrictedRegionErrorParser();

  RestrictedRegionException? parseException(Object error) {
    final restrictedRegionData = parse(error);
    if (restrictedRegionData == null) {
      return null;
    }

    return RestrictedRegionException(
      message: restrictedRegionData.message,
      country: restrictedRegionData.country,
      city: restrictedRegionData.city,
      region: restrictedRegionData.region,
      regionCode: restrictedRegionData.regionCode,
    );
  }

  RestrictedRegionErrorData? parse(Object error) {
    final dioError = switch (error) {
      final DioException dioException => dioException,
      final RequestExecutionException requestExecutionException
          when requestExecutionException.error is DioException =>
        requestExecutionException.error as DioException,
      _ => null,
    };
    if (dioError == null) {
      return null;
    }
    if (dioError.response?.statusCode != 403) {
      return null;
    }

    final responseData = _extractResponseData(dioError.response?.data);

    if (responseData == null) {
      return null;
    }

    if (responseData['code']?.toString().toUpperCase() != 'RESTRICTED_REGION') {
      return null;
    }

    final detailsRaw = responseData['details'];
    final details = detailsRaw is Map ? Map<String, dynamic>.from(detailsRaw) : null;
    final message = responseData['message']?.toString() ?? 'Operation not allowed in your region.';

    return RestrictedRegionErrorData(
      message: message,
      country: details?['country']?.toString(),
      city: details?['city']?.toString(),
      region: details?['region']?.toString(),
      regionCode: details?['regionCode']?.toString(),
    );
  }

  Map<String, dynamic>? _extractResponseData(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
