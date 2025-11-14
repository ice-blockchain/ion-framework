import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository_mock.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class IonCommunityTokensService {
  IonCommunityTokensService._({required TokenInfoRepository tokenInfoRepository})
    : _tokenInfoRepository = tokenInfoRepository;

  final TokenInfoRepository _tokenInfoRepository;

  static Future<IonCommunityTokensService> create({required NetworkClient networkClient}) async {
    final service = IonCommunityTokensService._(
      tokenInfoRepository: TokenInfoRepositoryMock(networkClient),
    );
    return service;
  }

  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) {
    return _tokenInfoRepository.getTokenInfo(ionConnectAddresses);
  }

  Future<NetworkSubscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) {
    return _tokenInfoRepository.subscribeToTokenInfo(ionConnectAddresses);
  }
}
