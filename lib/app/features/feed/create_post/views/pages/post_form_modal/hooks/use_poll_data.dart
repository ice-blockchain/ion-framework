// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/app/features/feed/polls/providers/poll_results_provider.r.dart';
import 'package:ion/app/features/feed/polls/utils/poll_utils.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

void usePollData(
  WidgetRef ref, {
  required EventReference? eventReference,
}) {
  useOnInit(
    () {
      if (eventReference != null) {
        final modifiedEntity =
            ref.read(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

        final pollData = switch (modifiedEntity) {
          final ModifiablePostEntity post => post.data.poll,
          _ => null,
        };

        if (pollData != null) {
          final voteCounts = ref.read(pollVoteCountsProvider(eventReference, pollData));
          final totalVotes = PollUtils.calculateTotalVotes(voteCounts);
          final pollDraft = PollUtils.pollDataToPollDraft(pollData, isVoted: totalVotes > 0);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ref.read(pollDraftNotifierProvider.notifier).draft = pollDraft,
          );
        }
      }
    },
  );
}
