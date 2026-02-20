// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/src/core/network/network_exception.dart';
import 'package:ion_identity_client/src/core/network/restricted_region_error_parser.dart';

class ProbeRestrictedRegionDataSource {
  const ProbeRestrictedRegionDataSource(
    this._baseUrl, {
    Iterable<Interceptor> interceptors = const [],
  }) : _interceptors = interceptors;

  final String _baseUrl;
  final Iterable<Interceptor> _interceptors;

  static const _bogusWalletId = 'wa-bogus-restricted-region-probe';
  static const _probePath = '/wallets/$_bogusWalletId/transactions';

  Future<void> probe() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
      ),
    );
    if (_interceptors.isNotEmpty) {
      dio.interceptors.addAll(_interceptors);
    }

    try {
      await dio.post<dynamic>(
        _probePath,
        options: Options(
          headers: const {},
        ),
      );
    } on DioException catch (error, stackTrace) {
      final restrictedRegionException = const RestrictedRegionErrorParser().parseException(error);
      if (restrictedRegionException != null) {
        throw restrictedRegionException;
      }
      throw RequestExecutionException(error, stackTrace);
    } catch (error, stackTrace) {
      throw RequestExecutionException(error, stackTrace);
    }
  }
}
