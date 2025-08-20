// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';

/// A configuration class for the ION Identity client, containing the necessary
/// identifiers and origin information required to initialize the client.
class IONIdentityConfig {
  /// Creates an instance of [IONIdentityConfig] with the specified [appId] and [origin].
  /// These parameters are essential for configuring the ION Identity client.
  IONIdentityConfig({
    required this.appId,
    required this.origin,
    this.interceptors,
  });

  /// The application identifier used to uniquely identify the app within the ION Identity API.
  final String appId;

  /// The origin URL from which the requests are made. This is used for validating
  /// and securing API requests.
  final String origin;

  /// The extra interceptors to use inside the ION Identity client.
  final List<Interceptor>? interceptors;

  @override
  String toString() =>
      'IONIdentityConfig(appId: $appId, origin: $origin, interceptors count: ${interceptors?.length ?? 0})';
}
