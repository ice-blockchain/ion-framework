// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'poll_vote_notifier.m.freezed.dart';
part 'poll_vote_notifier.m.g.dart';

@freezed
class PollVoteData with _$PollVoteData {
  const factory PollVoteData({
    required String pollEventId,
    required List<int> selectedOptionIndexes,
  }) = _PollVoteData;

  factory PollVoteData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final pollEventId = tags['a']?.first[1];
    final decoded = jsonDecode(eventMessage.content);

    if (pollEventId == null) {
      throw Exception('Missing required poll tags');
    }

    final selectedOptionIndexes = (decoded as List).map((e) => e as int).toList();

    return PollVoteData(
      pollEventId: pollEventId,
      selectedOptionIndexes: selectedOptionIndexes,
    );
  }
}

extension PollVoteDataX on PollVoteData {
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: 1754,
      tags: [
        ['a', pollEventId],
        ...tags,
      ],
      content: jsonEncode(selectedOptionIndexes),
    );
  }
}

/// Provider for voting on polls
@Riverpod(keepAlive: true)
class PollVoteNotifier extends _$PollVoteNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> vote(EventReference postReference, String optionId) async {
    if (state.isLoading) {
      return;
    }

    try {
      state = const AsyncValue.loading();

      final masterPubkey = ref.read(currentPubkeySelectorProvider);
      if (masterPubkey == null) {
        throw Exception('User must be logged in to vote');
      }

      final signer = await ref.read(currentUserIonConnectEventSignerProvider.future);
      if (signer == null) {
        throw Exception('Event signer is not available');
      }

      final pollEvent = await ref.read(
        ionConnectEntityProvider(eventReference: postReference).future,
      );
      if (pollEvent == null) {
        throw Exception('Poll event not loaded');
      }

      final selectedOptionIndex = int.parse(optionId);
      final pollEventId = postReference.toString();
      final pollVoteData = PollVoteData(
        pollEventId: pollEventId,
        selectedOptionIndexes: [selectedOptionIndex],
      );

      final voteEvent = await pollVoteData.toEventMessage(
        signer,
        tags: [
          ['b', masterPubkey],
        ],
      );

      final metadataBuilders = <UserEventsMetadataBuilder>[];
      if (pollEvent.masterPubkey != masterPubkey) {
        final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);
        metadataBuilders.add(userEventsMetadataBuilder);
      }
      await ref.read(ionConnectNotifierProvider.notifier).sendEvent(
            voteEvent,
            actionSource: ActionSource.user(pollEvent.masterPubkey),
            metadataBuilders: metadataBuilders,
          );

      state = const AsyncValue.data(null);
      return;
    } catch (e, stackTrace) {
      Logger.error(e, stackTrace: stackTrace, message: 'Failed to vote on poll');
      state = AsyncValue.error(e, stackTrace);
      return;
    }
  }
}
