// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';

typedef Decoder<T> = T Function(dynamic response, Map<String, List<String>> headers);

/// A generic network client that wraps around Dio and provides methods for
/// making GET and POST requests with automatic error handling and decoding
/// of JSON responses into typed results.
class NetworkClient {
  /// Creates an instance of [NetworkClient] with the provided Dio instance.
  /// This Dio instance is used to perform the actual network requests.
  NetworkClient({
    required this.dio,
  });

  /// The Dio instance used to perform network requests.
  final Dio dio;

  /// Sends a GET request to the specified [path] with optional [queryParams],
  /// and decodes the JSON response into a [Result] using the provided [decoder].
  ///
  /// Throws a [NetworkException] if the request fails or the response cannot be decoded.
  Future<Result> get<Result>(
    String path, {
    required Decoder<Result> decoder,
    JsonObject queryParams = const {},
    JsonObject headers = const {},
  }) async {
    return _makeRequest(
      request: () => dio.get<dynamic>(
        path,
        queryParameters: queryParams,
        options: Options(headers: headers),
      ),
      decoder: decoder,
    );
  }

  /// Sends a POST request to the specified [path] with optional [queryParams]
  /// and request [data], and decodes the JSON response into a [Result] using
  /// the provided [decoder].
  ///
  /// Throws a [NetworkException] if the request fails or the response cannot be decoded.
  Future<Result> post<Result>(
    String path, {
    required Decoder<Result> decoder,
    JsonObject queryParams = const {},
    JsonObject headers = const {},
    Object? data,
  }) async {
    return _makeRequest(
      request: () => dio.post<dynamic>(
        path,
        queryParameters: queryParams,
        data: data,
        options: Options(headers: headers),
      ),
      decoder: decoder,
    );
  }

  Future<Result> patch<Result>(
    String path, {
    required Decoder<Result> decoder,
    JsonObject queryParams = const {},
    JsonObject headers = const {},
    Object? data,
  }) async {
    return _makeRequest(
      request: () => dio.patch<dynamic>(
        path,
        queryParameters: queryParams,
        data: data,
        options: Options(headers: headers),
      ),
      decoder: decoder,
    );
  }

  Future<Result> put<Result>(
    String path, {
    required Decoder<Result> decoder,
    JsonObject queryParams = const {},
    JsonObject headers = const {},
    Object? data,
  }) async {
    return _makeRequest(
      request: () => dio.put<dynamic>(
        path,
        queryParameters: queryParams,
        data: data,
        options: Options(headers: headers),
      ),
      decoder: decoder,
    );
  }

  Future<Result> delete<Result>(
    String path, {
    required Decoder<Result> decoder,
    JsonObject queryParams = const {},
    JsonObject headers = const {},
    Object? data,
  }) async {
    return _makeRequest(
      request: () => dio.delete<dynamic>(
        path,
        queryParameters: queryParams,
        data: data,
        options: Options(headers: headers),
      ),
      decoder: decoder,
    );
  }

  /// A private method that executes the provided [request] function, handles
  /// potential errors, and decodes the JSON response using the provided [decoder].
  ///
  /// Throws a [NetworkException] if the request fails or the response cannot be decoded.
  Future<Result> _makeRequest<Result>({
    required Future<Response<dynamic>> Function() request,
    required Decoder<Result> decoder,
  }) async {
    try {
      final response = await request();
      final data = response.data;

      if (data == null) {
        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          return decoder(null, const {});
        }
        throw ResponseFormatException(data);
      }

      try {
        return decoder(data, response.headers.map);
      } catch (e, stackTrace) {
        throw DecodeException(data, e, stackTrace);
      }
    } on DioException catch (e, stackTrace) {
      if (UserAlreadyExistsException.isMatch(e)) {
        throw const UserAlreadyExistsException();
      }

      throw RequestExecutionException(e, stackTrace);
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw RequestExecutionException(e, stackTrace);
    }
  }
}
