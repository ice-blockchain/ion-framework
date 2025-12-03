import 'package:freezed_annotation/freezed_annotation.dart';

part 'okx_token_info.m.freezed.dart';
part 'okx_token_info.m.g.dart';

@freezed
class OkxTokenInfo with _$OkxTokenInfo {
  factory OkxTokenInfo({
    required String decimal,
  }) = _OkxTokenInfo;

  factory OkxTokenInfo.fromJson(Map<String, dynamic> json) => _$OkxTokenInfoFromJson(json);
}
