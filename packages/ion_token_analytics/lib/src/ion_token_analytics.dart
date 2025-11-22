// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/community_tokens_service.dart';
import 'package:ion_token_analytics/src/core/network_client_mock.dart';

class IonTokenAnalyticsClientOptions {
  IonTokenAnalyticsClientOptions({required this.baseUrl});

  final String baseUrl;
}

class IonTokenAnalyticsClient {
  IonTokenAnalyticsClient._({required this.communityTokens});

  final IonCommunityTokensService communityTokens;

  // Asynchronous factory constructor to create an instance of IonTokenAnalyticsClient (async to be future-proof)
  static Future<IonTokenAnalyticsClient> create({
    required IonTokenAnalyticsClientOptions options,
  }) async {
    // final networkClient = NetworkClient.fromBaseUrl(options.baseUrl);
    // TODO: Remove this when the API is ready
    final networkClient = NetworkClientMock(options.baseUrl);
    return IonTokenAnalyticsClient._(
      communityTokens: await IonCommunityTokensService.create(networkClient: networkClient),
    );
  }
}
