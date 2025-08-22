// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';

part 'poll_vote_state.f.freezed.dart';

@freezed
class PollVoteState with _$PollVoteState implements OptimisticModel {
  const factory PollVoteState({
    required EventReference eventReference,
    required List<int> voteCounts,
    required int? userVotedOptionIndex,
  }) = _PollVoteState;

  const PollVoteState._();

  @override
  String get optimisticId => eventReference.toString();
}
