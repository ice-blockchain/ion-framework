// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'suggest_creation_details_request.f.freezed.dart';
part 'suggest_creation_details_request.f.g.dart';

@freezed
class SuggestCreationDetailsRequest with _$SuggestCreationDetailsRequest {
  const factory SuggestCreationDetailsRequest({
    required String content,
    required CreatorInfo creator,
    required String contentId,
    @Default([]) List<String> contentVideoFrames,
  }) = _SuggestCreationDetailsRequest;

  factory SuggestCreationDetailsRequest.fromJson(Map<String, dynamic> json) =>
      _$SuggestCreationDetailsRequestFromJson(json);
}

@freezed
class CreatorInfo with _$CreatorInfo {
  const factory CreatorInfo({
    required String name,
    required String username,
    String? bio,
    String? website,
  }) = _CreatorInfo;

  factory CreatorInfo.fromJson(Map<String, dynamic> json) => _$CreatorInfoFromJson(json);
}
