// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_reaction.f.freezed.dart';

@freezed
class MessageReaction with _$MessageReaction {
  const factory MessageReaction({
    required String emoji,
    required List<String> masterPubkeys,
  }) = _MessageReaction;
}
