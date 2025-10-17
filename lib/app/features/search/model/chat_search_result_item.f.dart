// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_search_result_item.f.freezed.dart';

@freezed
class ChatSearchResultItem with _$ChatSearchResultItem {
  const factory ChatSearchResultItem({
    required String masterPubkey,
    String? lastMessageContent,
  }) = _ChatSearchResultItem;
}
