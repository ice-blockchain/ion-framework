import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/market_data.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';

class TokenInfoRepositoryMock implements TokenInfoRepository {
  TokenInfoRepositoryMock();

  static final List<CommunityToken> _mockTokens = [
    const CommunityToken(
      type: 'community',
      title: 'Mock Community Token',
      description: 'A mock community token for testing and development',
      imageUrl: 'https://example.com/mock-token.png',
      addresses: Addresses(blockchain: '0x1234567890abcdef', ionConnect: 'mock_ion_address_1'),
      creator: Creator(
        name: 'mockCreator',
        display: 'Mock Creator',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?img=1',
        ionConnect: 'mock_creator_address',
      ),
      marketData: MarketData(marketCap: 1847293, volume: 384729, holders: 247, priceUSD: 12.34),
    ),
    const CommunityToken(
      type: 'community',
      title: 'Test Token 2',
      description: 'Another test token with different market data',
      imageUrl: 'https://example.com/test-token-2.png',
      addresses: Addresses(blockchain: '0xfedcba0987654321', ionConnect: 'mock_ion_address_2'),
      creator: Creator(
        name: 'testCreator',
        display: 'Test Creator',
        verified: false,
        avatar: 'https://i.pravatar.cc/150?img=2',
        ionConnect: 'test_creator_address',
      ),
      marketData: MarketData(marketCap: 2938475, volume: 592847, holders: 418, priceUSD: 28.91),
    ),
    const CommunityToken(
      type: 'community',
      title: 'Dev Token',
      description: 'Development token for local testing',
      imageUrl: 'https://example.com/dev-token.png',
      addresses: Addresses(blockchain: '0xabcd1234efgh5678', ionConnect: 'mock_ion_address_3'),
      creator: Creator(
        name: 'devCreator',
        display: 'Dev Creator',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?img=3',
        ionConnect: 'dev_creator_address',
      ),
      marketData: MarketData(marketCap: 829461, volume: 147382, holders: 93, priceUSD: 6.78),
    ),
  ];

  @override
  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (_mockTokens.isEmpty) {
      return [];
    }

    return _mockTokens;
  }

  @override
  Future<Http2Subscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) async {
    final stream = Stream.periodic(const Duration(seconds: 1), (_) => _mockTokens);

    return Http2Subscription<List<CommunityToken>>(stream: stream, close: () async {});
  }
}
