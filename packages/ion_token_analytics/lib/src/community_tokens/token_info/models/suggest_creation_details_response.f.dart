// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'suggest_creation_details_response.f.freezed.dart';
part 'suggest_creation_details_response.f.g.dart';

@freezed
class SuggestCreationDetailsResponse with _$SuggestCreationDetailsResponse {
  const factory SuggestCreationDetailsResponse({
    required String ticker,
    required String name,
    required String picture,
  }) = _SuggestCreationDetailsResponse;

  factory SuggestCreationDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$SuggestCreationDetailsResponseFromJson(json);
}
