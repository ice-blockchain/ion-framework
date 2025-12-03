import 'package:freezed_annotation/freezed_annotation.dart';

part 'relay_quote_details.m.freezed.dart';
part 'relay_quote_details.m.g.dart';

@freezed
class RelayQuoteDetails with _$RelayQuoteDetails {
  factory RelayQuoteDetails({
    required String rate,
  }) = _RelayQuoteDetails;

  factory RelayQuoteDetails.fromJson(Map<String, dynamic> json) => _$RelayQuoteDetailsFromJson(json);
}
