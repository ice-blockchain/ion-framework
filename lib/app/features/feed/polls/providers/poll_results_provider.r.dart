// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_vote.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/vote_poll_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'poll_results_provider.r.g.dart';

class PollResults {
  const PollResults({
    required this.voteCounts,
    required this.userVotedOptionIndex,
  });

  final List<int> voteCounts;
  final int? userVotedOptionIndex;
}

@riverpod
class PollVoteCounts extends _$PollVoteCounts {
  @override
  List<int> build(EventReference eventReference, PollData pollData) {
    // Prefer optimistic counts when available
    final optimistic =
        ref.watch(pollVoteWatchProvider(eventReference.toString())).valueOrNull?.voteCounts;
    if (optimistic != null && optimistic.isNotEmpty) {
      return optimistic;
    }

    final cacheKey = EventCountResultEntity.cacheKeyBuilder(
      key: eventReference.toString(),
      type: EventCountResultType.pollVotes,
    );

    final counterEntity = ref.watch(
      ionConnectCacheProvider.select(
        cacheSelector<EventCountResultEntity>(cacheKey),
      ),
    );

    final allCacheEntries = ref.watch(ionConnectCacheProvider);
    final allCountEntries = allCacheEntries.values
        .map((entry) => entry.entity)
        .whereType<EventCountResultEntity>()
        .toList();

    var pollVoteCountEntity = counterEntity;
    if (pollVoteCountEntity == null) {
      final pollVoteCountEntities = allCountEntries
          .where(
            (entry) =>
                entry.data.type == EventCountResultType.pollVotes &&
                entry.data.key == eventReference.toString(),
          )
          .toList();

      if (pollVoteCountEntities.isNotEmpty) {
        pollVoteCountEntity = pollVoteCountEntities.first;
      }
    }

    if (pollVoteCountEntity != null) {
      final votesCount = pollVoteCountEntity.data.content as Map<String, dynamic>;
      return List<int>.generate(
        pollData.options.length,
        (i) => (votesCount['$i'] ?? 0) as int,
      );
    }

    final allPollVotes = allCacheEntries.values
        .map((entry) => entry.entity)
        .whereType<PollVoteEntity>()
        .where((vote) => vote.data.pollEventId == eventReference.toString())
        .toList();

    final votesByUser = <String, PollVoteEntity>{};
    for (final vote in allPollVotes) {
      final existingVote = votesByUser[vote.masterPubkey];
      if (existingVote == null ||
          vote.createdAt.toDateTime.isAfter(existingVote.createdAt.toDateTime)) {
        votesByUser[vote.masterPubkey] = vote;
      }
    }

    final voteCounts = List<int>.filled(pollData.options.length, 0);
    for (final vote in votesByUser.values) {
      for (final optionIndex in vote.data.selectedOptionIndexes) {
        if (optionIndex >= 0 && optionIndex < voteCounts.length) {
          voteCounts[optionIndex]++;
        }
      }
    }

    return voteCounts;
  }

  void addOne(int optionIndex) {
    final currentVoteCounts = state;
    if (optionIndex < 0 || optionIndex >= currentVoteCounts.length) return;

    final newVoteCounts = List<int>.from(currentVoteCounts);
    newVoteCounts[optionIndex] += 1;
    state = newVoteCounts;

    _updateCache(eventReference, newVoteCounts);
  }

  void _updateCache(EventReference eventReference, List<int> newVoteCounts) {
    final cacheKey = EventCountResultEntity.cacheKeyBuilder(
      key: eventReference.toString(),
      type: EventCountResultType.pollVotes,
    );

    final cacheEntry = ref.read(
      ionConnectCacheProvider.select(cacheSelector<EventCountResultEntity>(cacheKey)),
    );

    if (cacheEntry == null) {
      return;
    }

    final voteCountsMap = <String, dynamic>{};
    for (var i = 0; i < newVoteCounts.length; i++) {
      voteCountsMap['$i'] = newVoteCounts[i];
    }
    final updatedData = cacheEntry.data.copyWith(content: voteCountsMap);
    ref.read(ionConnectCacheProvider.notifier).cache(
          cacheEntry.copyWith(data: updatedData),
        );
  }
}

@riverpod
PollVoteEntity? userPollVote(Ref ref, EventReference eventReference) {
  final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) return null;

  final pollVote = ref.watch(
    ionConnectCacheProvider.select((allCacheEntries) {
      final allPollVotes = allCacheEntries.values
          .map((entry) => entry.entity)
          .whereType<PollVoteEntity>()
          .where(
            (vote) =>
                vote.masterPubkey == currentUserPubkey &&
                vote.data.pollEventId == eventReference.toString(),
          )
          .toList();

      return allPollVotes.firstOrNull;
    }),
  );
  return pollVote;
}

@riverpod
int? userVotedOptionIndex(Ref ref, EventReference eventReference) {
  final userVote = ref.watch(userPollVoteProvider(eventReference));

  if (userVote != null && userVote.data.selectedOptionIndexes.isNotEmpty) {
    return userVote.data.selectedOptionIndexes.first;
  }

  return null;
}

@riverpod
bool hasUserVoted(Ref ref, EventReference eventReference) {
  return ref.watch(userPollVoteProvider(eventReference)) != null;
}
