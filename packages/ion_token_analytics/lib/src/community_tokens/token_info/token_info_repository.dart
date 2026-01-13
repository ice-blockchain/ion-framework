// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/position.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/pricing_response.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/suggest_creation_details_request.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/suggest_creation_details_response.f.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class TokenInfoRepository {
  Future<CommunityToken?> getTokenInfo(String externalAddress);

  Future<NetworkSubscription<CommunityTokenBase>?> subscribeToTokenInfo(String externalAddress);

  Future<Position?> getHolderPosition(String tokenExternalAddress, String holderExternalAddress);

  Future<PricingResponse?> getPricing(String externalAddress, String type, String amount);

  Future<SuggestCreationDetailsResponse?> suggestCreationDetails(
    SuggestCreationDetailsRequest request,
  );
}
