// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/services/logger/logger.dart';
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

    // Safe cast only for logging purposes
    final payloadMap = (eventPayload as Map).cast<String, dynamic>();
    _logNip98HeaderReady(payloadMap);

    final payloadJson = jsonEncode(eventPayload);
    final headerValue = base64Encode(utf8.encode(payloadJson));

    return 'Bearer $headerValue';
  }

  static const int kind = 27235;
}

// Logs the header of the NIP-98 event
void _logNip98HeaderReady(Map<String, dynamic> eventPayload) {
  final payloadJson = jsonEncode(eventPayload);
  final tags = (eventPayload['tags'] as List<dynamic>?)?.cast<List<dynamic>>() ?? const [];

  String? absoluteUrl;
  String? requestMethod;
  String? payloadSha256First8;

  for (final tag in tags) {
    if (tag.isEmpty) continue;
    if (tag[0] == 'u' && tag.length > 1 && tag[1] is String) {
      absoluteUrl = tag[1] as String;
    } else if (tag[0] == 'method' && tag.length > 1 && tag[1] is String) {
      requestMethod = tag[1] as String;
    } else if (tag[0] == 'payload' && tag.length > 1 && tag[1] is String) {
      final hexStr = tag[1] as String;
      payloadSha256First8 = hexStr.length >= 8 ? hexStr.substring(0, 8) : hexStr;
    }
  }

  Logger.info(
    'NOSTR.NIP98 header_ready nip98.u=${absoluteUrl ?? 'null'} nip98.method=${requestMethod ?? 'null'} nip98.payload_sha256_first8=${payloadSha256First8 ?? 'null'} event_size_bytes=${payloadJson.length}',
  );
}
