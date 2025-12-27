// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/extensions/event_message.dart';
import 'package:ion/app/features/feed/polls/providers/poll_vote_notifier.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';

part 'poll_vote.f.freezed.dart';

@Freezed(equal: false)
class PollVoteEntity with _$PollVoteEntity, IonConnectEntity, ImmutableEntity, CacheableEntity {
  const factory PollVoteEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required PollVoteData data,
    EventMessage? eventMessage,
  }) = _PollVoteEntity;

  const PollVoteEntity._();

  factory PollVoteEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw Exception('Incorrect event kind ${eventMessage.kind}, expected $kind');
    }

    return PollVoteEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: PollVoteData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );
  }

  static const kind = 1754;
}
