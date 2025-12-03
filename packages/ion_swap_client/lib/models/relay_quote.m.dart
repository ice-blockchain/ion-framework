import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/relay_quote_details.m.dart';

part 'relay_quote.m.freezed.dart';
part 'relay_quote.m.g.dart';

@freezed
class RelayQuote with _$RelayQuote {
  factory RelayQuote({
    required RelayQuoteDetails details,
  }) = _RelayQuote;

  factory RelayQuote.fromJson(Map<String, dynamic> json) => _$RelayQuoteFromJson(json);
}
