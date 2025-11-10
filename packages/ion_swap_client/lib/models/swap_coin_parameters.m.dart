import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_coin_parameters.m.freezed.dart';
part 'swap_coin_parameters.m.g.dart';

@freezed
class SwapCoinParameters with _$SwapCoinParameters {
  factory SwapCoinParameters({
    required String sellNetworkId,
    required String buyNetworkId,

    required String userSellAddress,
    required String userBuyAddress,

    required String sellCoinContractAddress,
    required String buyCoinContractAddress,

    required String sellCoinNetworkName,
    required String buyCoinNetworkName,   

    required String amount,
  }) = _SwapCoinParameters;

  factory SwapCoinParameters.fromJson(Map<String, dynamic> json) => _$SwapCoinParametersFromJson(json);
}
