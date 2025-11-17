// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/polls/models/poll_answer.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_draft.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'poll_draft_provider.r.g.dart';

@riverpod
class PollDraftNotifier extends _$PollDraftNotifier {
  @override
  PollDraft build() => PollDraft.initial();

  void addAnswer() {
    state = state.copyWith(answers: [...state.answers, PollAnswer.empty()]);
  }

  void updateAnswer(int index, String newText) {
    if (index >= 0 && index < state.answers.length) {
      state = state.copyWith(
        answers: [
          for (int i = 0; i < state.answers.length; i++)
            if (i == index) state.answers[i].copyWith(text: newText) else state.answers[i],
        ],
      );
    }
  }

  void removeAnswer(int index) {
    if (index >= 0 && index < state.answers.length) {
      state = state.copyWith(
        answers: [
          for (int i = 0; i < state.answers.length; i++)
            if (i != index) state.answers[i],
        ],
      );
    }
  }

  void setLengthDays(int days) {
    state = state.copyWith(lengthDays: days);
  }

  void setLengthHours(int hours) {
    state = state.copyWith(lengthHours: hours);
  }

  void markPollAdded() {
    state = state.copyWith(added: true);
  }

  void reset() {
    state = PollDraft.initial();
  }

  set draft(PollDraft draft) {
    state = draft;
  }
}
