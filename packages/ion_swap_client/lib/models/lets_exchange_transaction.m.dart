import 'package:freezed_annotation/freezed_annotation.dart';

part 'lets_exchange_transaction.m.freezed.dart';
part 'lets_exchange_transaction.m.g.dart';

@freezed
class LetsExchangeTransaction with _$LetsExchangeTransaction {
  factory LetsExchangeTransaction({
    @JsonKey(name: 'transaction_id') required String transactionId,
  }) = _LetsExchangeTransaction;

  factory LetsExchangeTransaction.fromJson(Map<String, dynamic> json) => _$LetsExchangeTransactionFromJson(json);
}
