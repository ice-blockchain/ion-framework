import 'package:ion_token_analytics/src/community_tokens/community_tokens_service.dart';
import 'package:ion_token_analytics/src/http2_client/http2_client.dart';

class IonTokenAnalyticsClientOptions {
  IonTokenAnalyticsClientOptions({required this.baseUrl});

  final String baseUrl;
}

class IonTokenAnalyticsClient {
  IonTokenAnalyticsClient._({required this.communityTokensService});

  final IonCommunityTokensService communityTokensService;

  // Asynchronous factory constructor to create an instance of IonTokenAnalyticsClient (async to be future-proof)
  static Future<IonTokenAnalyticsClient> create({
    required IonTokenAnalyticsClientOptions options,
  }) async {
    final httpClient = Http2Client.fromBaseUrl(options.baseUrl);
    return IonTokenAnalyticsClient._(
      communityTokensService: await IonCommunityTokensService.create(networkClient: httpClient),
    );
  }
}
