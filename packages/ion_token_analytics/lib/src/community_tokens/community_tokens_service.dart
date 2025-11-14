import 'package:ion_token_analytics/ion_token_analytics.dart';

class IonCommunityTokensService {
  IonCommunityTokensService._({required TokenInfoRepository tokenInfoRepository})
    : _tokenInfoRepository = tokenInfoRepository;

  final TokenInfoRepository _tokenInfoRepository;

  static Future<IonCommunityTokensService> create({required Http2Client networkClient}) async {
    final service = IonCommunityTokensService._(
      tokenInfoRepository: TokenInfoRepositoryRemote(networkClient),
    );
    return service;
  }

  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) {
    return _tokenInfoRepository.getTokenInfo(ionConnectAddresses);
  }

  Future<Http2Subscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) {
    return _tokenInfoRepository.subscribeToTokenInfo(ionConnectAddresses);
  }
}
