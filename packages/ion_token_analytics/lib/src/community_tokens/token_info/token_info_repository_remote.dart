import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';

class TokenInfoRepositoryRemote implements TokenInfoRepository {
  TokenInfoRepositoryRemote(this.client);

  final Http2Client client;

  @override
  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) async {
    final queryParameters = <String, String>{};
    for (var i = 0; i < ionConnectAddresses.length; i++) {
      queryParameters['ionConnectAddresses[$i]'] = ionConnectAddresses[i];
    }

    final response = await client.request<List<dynamic>>(
      '/v1/community-tokens',
      queryParameters: queryParameters,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch community tokens: HTTP ${response.statusCode}');
    }

    if (response.data == null) {
      throw Exception('Empty response received for community tokens');
    }

    return response.data!
        .map((json) => CommunityToken.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Http2Subscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) async {
    final queryParameters = <String, String>{};
    for (var i = 0; i < ionConnectAddresses.length; i++) {
      queryParameters['ionConnectAddresses[$i]'] = ionConnectAddresses[i];
    }

    final subscription = await client.subscribe<List<dynamic>>(
      '/v1/community-tokens',
      queryParameters: queryParameters,
    );

    final tokenStream = subscription.stream.map(
      (data) => data.map((json) => CommunityToken.fromJson(json as Map<String, dynamic>)).toList(),
    );

    return Http2Subscription<List<CommunityToken>>(stream: tokenStream, close: subscription.close);
  }
}
