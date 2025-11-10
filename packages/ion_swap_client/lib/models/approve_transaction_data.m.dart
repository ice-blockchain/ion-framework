import 'package:freezed_annotation/freezed_annotation.dart';

part 'approve_transaction_data.m.freezed.dart';
part 'approve_transaction_data.m.g.dart';

@freezed
class ApproveTransactionData with _$ApproveTransactionData {
  factory ApproveTransactionData({
    required String data,
    required String dexContractAddress,
    required String gasLimit,
    required String gasPrice,
  }) = _ApproveTransactionData;

  factory ApproveTransactionData.fromJson(Map<String, dynamic> json) =>
      _$ApproveTransactionDataFromJson(json);
}
