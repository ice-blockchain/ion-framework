// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_quote_data.m.freezed.dart';
part 'swap_quote_data.m.g.dart';

@freezed
class SwapQuoteData with _$SwapQuoteData {
  factory SwapQuoteData({
    required String chainIndex,
  }) = _SwapQuoteData;

  factory SwapQuoteData.fromJson(Map<String, dynamic> json) => _$SwapQuoteDataFromJson(json);
}
