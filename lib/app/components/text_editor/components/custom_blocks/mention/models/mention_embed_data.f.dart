// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_embed_data.f.freezed.dart';
part 'mention_embed_data.f.g.dart';

// Data model for mention embed structure.
// Used when creating and reading mention embeds in Quill documents.
@freezed
class MentionEmbedData with _$MentionEmbedData {
  const factory MentionEmbedData({
    required String pubkey,
    required String username,
    String? id, // Unique instance ID for distinguishing duplicate mentions
  }) = _MentionEmbedData;

  const MentionEmbedData._();

  factory MentionEmbedData.fromJson(Map<String, dynamic> json) => _$MentionEmbedDataFromJson(json);
}
