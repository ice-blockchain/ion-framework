import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_balance_state.f.freezed.dart';

/// Used to describe balance of the coin via balance provider.
@freezed
class CoinBalanceState with _$CoinBalanceState {
  const factory CoinBalanceState({
    @Default(0) double amount, // after converting by (amount / 10^decimal)
    @Default(0) double balanceUSD,
  }) = _CoinBalanceState;

  const CoinBalanceState._();
}
