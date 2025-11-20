// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/feed/polls/models/poll_answer.f.dart';

part 'poll_draft.f.freezed.dart';

@freezed
class PollDraft with _$PollDraft {
  const factory PollDraft({
    required List<PollAnswer> answers,
    required int lengthDays,
    required int lengthHours,
    required bool added,
    required bool isVoted,
  }) = _PollDraft;

  factory PollDraft.initial() => PollDraft(
        answers: [PollAnswer.empty()],
        lengthDays: 1,
        lengthHours: 0,
        added: false,
        isVoted: false,
      );
}

extension PollDraftExtension on PollDraft {
  int get ttlSeconds => (lengthDays * 24 * 3600) + (lengthHours * 3600);
}
