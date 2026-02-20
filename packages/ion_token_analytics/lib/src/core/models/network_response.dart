// SPDX-License-Identifier: ice License 1.0

/// Response from a [NetworkClient] request that includes both data and headers.
class NetworkResponse<T> {
  NetworkResponse({required this.data, this.headers});

  final T data;
  final Map<String, String>? headers;
}
