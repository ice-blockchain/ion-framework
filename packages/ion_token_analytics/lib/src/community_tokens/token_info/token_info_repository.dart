import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';

abstract class TokenInfoRepository {
  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses);

  Future<Http2Subscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  );
}
