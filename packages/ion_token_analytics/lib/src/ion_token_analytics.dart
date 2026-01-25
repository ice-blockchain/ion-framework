// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/community_tokens_service.dart';
import 'package:ion_token_analytics/src/core/logger.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class IonTokenAnalyticsClientOptions {
  IonTokenAnalyticsClientOptions({required this.baseUrl, this.authToken, this.logger});

  final String baseUrl;
  final String? authToken;
  final AnalyticsLogger? logger;
}

class IonTokenAnalyticsClient {
  IonTokenAnalyticsClient._({required this.communityTokens, required NetworkClient networkClient})
    : _networkClient = networkClient;

  final IonCommunityTokensService communityTokens;
  final NetworkClient _networkClient;

  // Asynchronous factory constructor to create an instance of IonTokenAnalyticsClient (async to be future-proof)
  static Future<IonTokenAnalyticsClient> create({
    required IonTokenAnalyticsClientOptions options,
  }) async {
    final networkClient = NetworkClient.fromBaseUrl(
      options.baseUrl,
      authToken: options.authToken,
      logger: options.logger,
    );
    return IonTokenAnalyticsClient._(
      communityTokens: await IonCommunityTokensService.create(networkClient: networkClient),
      networkClient: networkClient,
    );
  }

  /// Forces the underlying network client to drop the current connection.
  ///
  /// Useful when a stale socket is detected (e.g., after backgrounding).
  Future<void> forceDisconnect() {
    return _networkClient.forceDisconnect();
  }

  /// Disposes the client and releases all resources.
  ///
  /// This should be called when the client is no longer needed, such as when
  /// the app goes to background. After calling this method, the client should
  /// not be used again.
  Future<void> dispose() async {
    await _networkClient.dispose();
  }
}
