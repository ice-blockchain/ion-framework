import 'package:freezed_annotation/freezed_annotation.dart';

part 'relay_currency.m.freezed.dart';
part 'relay_currency.m.g.dart';

@freezed
class RelayCurrency with _$RelayCurrency {
  factory RelayCurrency({
    required String id,
    required String symbol,
    required String name,
    required String address,
    required int decimals,
  }) = _RelayCurrency;

  factory RelayCurrency.fromJson(Map<String, dynamic> json) => _$RelayCurrencyFromJson(json);
}
