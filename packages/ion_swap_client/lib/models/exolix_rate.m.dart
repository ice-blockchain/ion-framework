import 'package:freezed_annotation/freezed_annotation.dart';

part 'exolix_rate.m.freezed.dart';
part 'exolix_rate.m.g.dart';

@freezed
class ExolixRate with _$ExolixRate {
  factory ExolixRate({
    required int fromAmount,
    required int toAmount,
    required int rate,
    required String? message,
    required int minAmount,
    required int withdrawMin,
    required int maxAmount,
  }) = _ExolixRate;

  factory ExolixRate.fromJson(Map<String, dynamic> json) => _$ExolixRateFromJson(json);
}
