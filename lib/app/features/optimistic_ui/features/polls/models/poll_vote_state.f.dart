import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';

part 'poll_vote_state.f.freezed.dart';

@freezed
class PollVoteState with _$PollVoteState implements OptimisticModel {
  const factory PollVoteState({
    required PollData pollData,
    required List<int> voteCounts,
    required int userVotedOptionIndex,
    required EventReference eventReference,
  }) = _PollVoteState;

  const PollVoteState._();

  @override
  String get optimisticId => pollData.ttl.toString();
}
