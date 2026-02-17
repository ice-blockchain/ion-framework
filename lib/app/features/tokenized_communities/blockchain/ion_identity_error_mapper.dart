// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion_identity_client/ion_identity.dart';

class IonIdentityErrorMapper {
  const IonIdentityErrorMapper();

  RestrictedRegionException? mapRestrictedRegion(Object error) {
    if (error is! RequestExecutionException) {
      return null;
    }

    if (error.error is! DioException) {
      return null;
    }

    final dioError = error.error as DioException;
    if (dioError.response?.statusCode != 403) {
      return null;
    }

    final data = dioError.response?.data;
    if (data is! Map) {
      return null;
    }

    final dataMap = Map<String, dynamic>.from(data);
    if (dataMap['code']?.toString().toUpperCase() != 'RESTRICTED_REGION') {
      return null;
    }

    final detailsRaw = dataMap['details'];
    final details = detailsRaw is Map ? Map<String, dynamic>.from(detailsRaw) : null;
    final message = dataMap['message']?.toString() ?? 'Operation not allowed in your region.';

    return RestrictedRegionException(
      message: message,
      country: details?['country']?.toString(),
      city: details?['city']?.toString(),
      region: details?['region']?.toString(),
      regionCode: details?['regionCode']?.toString(),
    );
  }
}
