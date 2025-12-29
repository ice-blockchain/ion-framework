// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

part 'user_delegation.f.freezed.dart';

enum DelegationStatus { active, inactive, revoked }

@Freezed(equal: false)
class UserDelegationEntity
    with IonConnectEntity, CacheableEntity, ReplaceableEntity, _$UserDelegationEntity
    implements EntityEventSerializable, DbCacheableEntity {
  const factory UserDelegationEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required String signature,
    required int createdAt,
    required UserDelegationData data,
  }) = _UserDelegationEntity;

  const UserDelegationEntity._();

  /// https://github.com/nostr-protocol/nips/pull/1482/files
  factory UserDelegationEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    return UserDelegationEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.pubkey,
      signature: eventMessage.sig!,
      createdAt: eventMessage.createdAt,
      data: UserDelegationData.fromEventMessage(eventMessage),
    );
  }

  @override
  FutureOr<EventMessage> toEntityEventMessage() {
    return EventMessage.fromData(
      signer: SimpleSigner(pubkey, signature),
      createdAt: createdAt,
      kind: UserDelegationEntity.kind,
      content: '',
      tags: data.tags,
    );
  }

  static const int kind = 10100;
}

@freezed
class UserDelegationData
    with _$UserDelegationData
    implements ReplaceableEntityData, EventSerializable {
  const factory UserDelegationData({
    required List<UserDelegate> delegates,
  }) = _UserDelegationData;

  const UserDelegationData._();

  factory UserDelegationData.fromEventMessage(EventMessage eventMessage) {
    final delegates =
        eventMessage.tags.where((tag) => tag[0] == 'p').map(UserDelegate.fromTag).toList();

    return UserDelegationData(delegates: delegates);
  }

  @override
  FutureOr<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) {
    return EventMessage.fromData(
      content: '',
      signer: signer,
      createdAt: createdAt,
      kind: UserDelegationEntity.kind,
      tags: [
        ...tags,
        ...delegates.map((delegate) => delegate.toTag()),
      ],
    );
  }

  bool validate(EventMessage message) {
    final delegates = activeDelegates();

    final delegate = delegates[message.pubkey];
    if (delegate != null) {
      final kinds = delegate.kinds;
      return kinds == null || kinds.contains(message.kind);
    }
    return false;
  }

  Map<String, UserDelegate> activeDelegates() {
    final currentDelegates = delegates.fold(<String, UserDelegate>{}, (currentDelegates, delegate) {
      /// `inactive` and `revoked` attestations invalidate all previous `active` attestations,
      /// and subsequent `active` attestations are considered invalid as well
      if (currentDelegates[delegate.pubkey]?.status == DelegationStatus.inactive ||
          currentDelegates[delegate.pubkey]?.status == DelegationStatus.revoked) {
        return currentDelegates;
      }

      currentDelegates[delegate.pubkey] = delegate;
      return currentDelegates;
    });

    final activeDelegates = currentDelegates
      ..removeWhere((_, delegate) => delegate.status != DelegationStatus.active);

    return activeDelegates;
  }

  bool hasDelegateFor({required String pubkey}) {
    return delegates.any((delegate) => delegate.pubkey == pubkey);
  }

  List<List<String>> get tags {
    return delegates.map((delegate) => delegate.toTag()).toList();
  }

  @override
  ReplaceableEventReference toReplaceableEventReference(String pubkey) {
    return ReplaceableEventReference(
      kind: UserDelegationEntity.kind,
      masterPubkey: pubkey,
    );
  }
}

@freezed
class UserDelegate with _$UserDelegate {
  const factory UserDelegate({
    required String pubkey,
    required DateTime time,
    required DelegationStatus status,
    @Default('') String relay,
    List<int>? kinds,
  }) = _UserDelegate;

  const UserDelegate._();

  factory UserDelegate.fromTag(List<String> tag) {
    /// "p", <pubkey>, <main relay URL>, <attestation string>
    final [_, pubkey, relay, attestationString] = tag;

    /// active:<timestamp>:<kinds comma separated list, optional>
    final attestation = attestationString.split(':');
    final statusName = attestation[0];
    final timestamp = attestation[1];
    final kindsString = (attestation.length > 2) ? attestation[2] : null;

    final status = DelegationStatus.values.byName(statusName);
    final time = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    final kinds = kindsString?.split(',').map(int.parse).toList();

    return UserDelegate(pubkey: pubkey, relay: relay, status: status, time: time, kinds: kinds);
  }

  List<String> toTag() {
    final attestationParts = [status.toShortString(), time.millisecondsSinceEpoch ~/ 1000];
    if (kinds.emptyOrValue.isNotEmpty) {
      attestationParts.add(kinds!.join(','));
    }
    return ['p', pubkey, relay, attestationParts.join(':')];
  }
}
