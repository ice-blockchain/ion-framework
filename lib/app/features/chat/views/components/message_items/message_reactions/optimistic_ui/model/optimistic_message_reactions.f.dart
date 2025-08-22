// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/chat/model/message_reaction.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';

part 'optimistic_message_reactions.f.freezed.dart';

@freezed
class OptimisticMessageReactions with _$OptimisticMessageReactions implements OptimisticModel {
  const factory OptimisticMessageReactions({
    required EventReference eventReference,
    required List<MessageReaction> reactions,
  }) = _OptimisticMessageReactions;

  const OptimisticMessageReactions._();

  @override
  String get optimisticId => eventReference.toString();
}
