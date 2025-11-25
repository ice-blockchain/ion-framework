import 'package:freezed_annotation/freezed_annotation.dart';

part 'exolix_transaction.m.freezed.dart';
part 'exolix_transaction.m.g.dart';

@freezed
class ExolixTransaction with _$ExolixTransaction {
  factory ExolixTransaction({
    required String id,
    required num amount,
    required TransactionStatus status,
    required String depositAddress,
  }) = _ExolixTransaction;

  factory ExolixTransaction.fromJson(Map<String, dynamic> json) =>
      _$ExolixTransactionFromJson(json);
}

enum TransactionStatus {
  wait,
  confirmation,
  confirmed,
  exchanging,
  sending,
  success,
  overdue,
  refunded,
}
