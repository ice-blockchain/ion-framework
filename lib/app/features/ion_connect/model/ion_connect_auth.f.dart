// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';

part 'ion_connect_auth.f.freezed.dart';

//TODO: move core nostr related models to nostr-lib
@freezed
class IonConnectAuth with _$IonConnectAuth implements EventSerializable {
  const factory IonConnectAuth({
    required String url,
    required String method,
    List<int>? payload,
    UserDelegationEntity? userDelegation,
  }) = _IonConnectAuth;

  const IonConnectAuth._();

  /// https://github.com/nostr-protocol/nips/blob/master/98.md
  @override
  Future<EventMessage> toEventMessage(
    EventSigner signer, {
    List<List<String>> tags = const [],
    int? createdAt,
  }) async {
    final eventTags = [
      ...tags,
      ['u', url],
      ['method', method],
    ];

    if (payload != null) {
      final hash = await Sha256().hash(payload!);
      eventTags.add(
        ['payload', hex.encode(hash.bytes)],
      );
    }

    if (userDelegation != null) {
      final attestationJson = jsonEncode(
        (await userDelegation!.toEntityEventMessage()).toJson().last,
      );
      eventTags.add(['attestation', attestationJson]);
    }

    return EventMessage.fromData(
      signer: signer,
      createdAt: createdAt,
      kind: kind,
      tags: eventTags,
      content: '',
    );
  }

  String toAuthorizationHeader(EventMessage event) {
    final eventPayload = event.toJson().last;

    final payloadJson = jsonEncode(eventPayload);
    final headerValue = base64Encode(utf8.encode(payloadJson));

    return 'Bearer $headerValue';
  }

  static const int kind = 27235;
}
