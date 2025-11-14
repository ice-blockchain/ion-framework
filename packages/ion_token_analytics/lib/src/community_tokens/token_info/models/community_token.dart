import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/market_data.dart';

part 'community_token.freezed.dart';
part 'community_token.g.dart';

@freezed
class CommunityToken with _$CommunityToken {
  const factory CommunityToken({
    required String type,
    required String title,
    required String description,
    required String imageUrl,
    required Addresses addresses,
    required Creator creator,
    required MarketData marketData,
  }) = _CommunityToken;

  factory CommunityToken.fromJson(Map<String, dynamic> json) => _$CommunityTokenFromJson(json);
}
