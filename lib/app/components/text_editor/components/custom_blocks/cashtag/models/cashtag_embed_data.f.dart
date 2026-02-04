// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cashtag_embed_data.f.freezed.dart';
part 'cashtag_embed_data.f.g.dart';

// Data model for cashtag embed structure.
// Used when creating and reading cashtag embeds in Quill documents.
@freezed
class CashtagEmbedData with _$CashtagEmbedData {
  const factory CashtagEmbedData({
    // Ticker symbol (e.g. "ETH"). JSON key kept as 'symbolGroup' for not breaking existing data.
    @JsonKey(name: 'symbolGroup') required String ticker,
    required String externalAddress,
    String? id, // Unique instance ID for distinguishing duplicate cashtags
  }) = _CashtagEmbedData;

  factory CashtagEmbedData.fromJson(Map<String, dynamic> json) => _$CashtagEmbedDataFromJson(json);

  const CashtagEmbedData._();

  String get displayTicker => ticker.toUpperCase();
}
