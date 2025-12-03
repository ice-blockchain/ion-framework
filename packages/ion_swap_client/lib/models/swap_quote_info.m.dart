import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_quote_info.m.freezed.dart';
part 'swap_quote_info.m.g.dart';

@freezed
class SwapQuoteInfo with _$SwapQuoteInfo {
  factory SwapQuoteInfo({
    required SwapQuoteInfoType type,
    required double priceForSellTokenInBuyToken,
    required SwapQuoteInfoSource source,
    int? swapImpact,
    String? networkFee,
    String? protocolFee,
    String? slippage,
  }) = _SwapQuoteInfo;

  factory SwapQuoteInfo.fromJson(Map<String, dynamic> json) => _$SwapQuoteInfoFromJson(json);
}

enum SwapQuoteInfoType {
  cexOrDex,
  bridge;
}

enum SwapQuoteInfoSource {
  exolix,
  letsExchange,
  okx, 
  relay,
}
