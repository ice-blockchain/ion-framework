import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/data/models/swap_quote_data.m.dart';

part 'swap_quote_response.m.freezed.dart';
part 'swap_quote_response.m.g.dart';

@freezed
class SwapQuoteResponse with _$SwapQuoteResponse {
  factory SwapQuoteResponse({
    required String code,
    @JsonKey(name: 'data') required List<SwapQuoteData> quotes,
  }) = _SwapQuoteResponse;

  factory SwapQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapQuoteResponseFromJson(json);
}
