// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/community_tokens_service.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class IonTokenAnalyticsClientOptions {
  IonTokenAnalyticsClientOptions({required this.baseUrl, this.authToken});

  final String baseUrl;
  final String? authToken;
}

class IonTokenAnalyticsClient {
  factory IonTokenAnalyticsClient.create({required IonTokenAnalyticsClientOptions options}) {
    final networkClient = NetworkClient.fromBaseUrl(options.baseUrl, authToken: options.authToken);
    return IonTokenAnalyticsClient._(
      communityTokens: IonCommunityTokensService.create(networkClient: networkClient),
    );
  }
  IonTokenAnalyticsClient._({required this.communityTokens});

  final IonCommunityTokensService communityTokens;
}
