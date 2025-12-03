import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/exolix_rate.m.dart';
import 'package:ion_swap_client/models/lets_exchange_info.m.dart';
import 'package:ion_swap_client/models/relay_quote.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';

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
    ExolixRate? exolixQuote,
    LetsExchangeInfo? letsExchangeQuote,
    SwapQuoteData? okxQuote,
    RelayQuote? relayQuote,
    String? relayDepositAmount,
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
