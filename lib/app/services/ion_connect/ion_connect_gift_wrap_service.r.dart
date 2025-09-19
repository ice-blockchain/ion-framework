// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/compression_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/services/ion_connect/ed25519_key_store.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:nip44/nip44.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_gift_wrap_service.r.g.dart';

@riverpod
Future<IonConnectGiftWrapService> ionConnectGiftWrapService(Ref ref) async =>
    IonConnectGiftWrapServiceImpl(
      encryptedMessageService: await ref.watch(encryptedMessageServiceProvider.future),
    );

abstract class IonConnectGiftWrapService {
  Future<EventMessage> createWrap({
    required EventMessage event,
    required DateTime randomCreatedAt,
    required String receiverPubkey,
    required String receiverMasterPubkey,
    required List<String> contentKinds,
    List<String>? expirationTag,
    CompressionAlgorithm compressionAlgorithm = CompressionAlgorithm.none,
  });

  Future<EventMessage> decodeWrap({
    required String content,
    required String senderPubkey,
    required String privateKey,
    CompressionAlgorithm compressionAlgorithm = CompressionAlgorithm.none,
  });
}

class IonConnectGiftWrapServiceImpl implements IonConnectGiftWrapService {
  const IonConnectGiftWrapServiceImpl({
    required EncryptedMessageService encryptedMessageService,
  }) : _encryptedMessageService = encryptedMessageService;

  final EncryptedMessageService _encryptedMessageService;

  @override
  Future<EventMessage> createWrap({
    required EventMessage event,
    required DateTime randomCreatedAt,
    required String receiverPubkey,
    required String receiverMasterPubkey,
    required List<String> contentKinds,
    CompressionAlgorithm compressionAlgorithm = CompressionAlgorithm.none,
    List<String>? expirationTag,
  }) async {
    final oneTimeSigner = await Ed25519KeyStore.generate();

    final encodedEvent = jsonEncode(event.toJson().last);

    final encryptedEvent = await _encryptedMessageService.encryptMessage(
      encodedEvent,
      publicKey: receiverPubkey,
      privateKey: oneTimeSigner.privateKey,
      compressionAlgorithm: compressionAlgorithm,
    );

    return EventMessage.fromData(
      kind: IonConnectGiftWrapEntity.kind,
      createdAt: randomCreatedAt.microsecondsSinceEpoch,
      signer: oneTimeSigner,
      content: encryptedEvent,
      tags: [
        [RelatedPubkey.tagName, receiverMasterPubkey, '', receiverPubkey],
        ['k', ...contentKinds],
        if (expirationTag != null) expirationTag,
        if (compressionAlgorithm != CompressionAlgorithm.none)
          CompressionTag(value: compressionAlgorithm.name).toTag(),
      ],
    );
  }

  @override
  Future<EventMessage> decodeWrap({
    required String content,
    required String senderPubkey,
    required String privateKey,
    CompressionAlgorithm compressionAlgorithm = CompressionAlgorithm.none,
  }) async {
    final decryptedContent = await _encryptedMessageService.decryptMessage(
      content,
      publicKey: senderPubkey,
      privateKey: privateKey,
      compressionAlgorithm: compressionAlgorithm,
    );

    return EventMessage.fromPayloadJson(
      jsonDecode(decryptedContent) as Map<String, dynamic>,
    );
  }
}
