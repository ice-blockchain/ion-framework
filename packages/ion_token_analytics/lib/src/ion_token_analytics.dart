// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/community_tokens_service.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class IonTokenAnalyticsClientOptions {
  IonTokenAnalyticsClientOptions({required this.baseUrl, this.authToken});

  final String baseUrl;
  final String? authToken;
}

class IonTokenAnalyticsClient {
  IonTokenAnalyticsClient._({required this.communityTokens});

  final IonCommunityTokensService communityTokens;

  // Asynchronous factory constructor to create an instance of IonTokenAnalyticsClient (async to be future-proof)
  static Future<IonTokenAnalyticsClient> create({
    required IonTokenAnalyticsClientOptions options,
  }) async {
    final networkClient = NetworkClient.fromBaseUrl(options.baseUrl, authToken: options.authToken);
    return IonTokenAnalyticsClient._(
      communityTokens: await IonCommunityTokensService.create(networkClient: networkClient),
    );
  }
}
