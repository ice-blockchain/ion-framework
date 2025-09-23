// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/string.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/compression_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:nip44/nip44.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_seal_service.r.g.dart';

@riverpod
Future<IonConnectSealService> ionConnectSealService(Ref ref) async => IonConnectSealServiceImpl(
      currentUserMasterPubkey: ref.watch(currentPubkeySelectorProvider).emptyOrValue,
      encryptedMessageService: await ref.watch(encryptedMessageServiceProvider.future),
    );

abstract class IonConnectSealService {
  Future<EventMessage> createSeal(
    EventMessage rumor,
    EventSigner signer,
    String receiverPubkey, {
    CompressionAlgorithm compressionAlgorithm = CompressionAlgorithm.none,
  });

  Future<EventMessage> decodeSeal(
    String content,
    String senderPubkey,
    String privateKey, {
    CompressionAlgorithm compressionAlgorithm = CompressionAlgorithm.none,
  });
}

class IonConnectSealServiceImpl implements IonConnectSealService {
  const IonConnectSealServiceImpl({
    required this.currentUserMasterPubkey,
    required EncryptedMessageService encryptedMessageService,
  }) : _encryptedMessageService = encryptedMessageService;

  static const int kind = 13;

  final String currentUserMasterPubkey;
  final EncryptedMessageService _encryptedMessageService;

  @override
  Future<EventMessage> createSeal(
    EventMessage rumor,
    EventSigner signer,
    String receiverPubkey, {
    CompressionAlgorithm compressionAlgorithm = CompressionAlgorithm.none,
  }) async {
    final encodedRumor = jsonEncode(rumor.toJson().last);

    final encryptedRumor = await _encryptedMessageService.encryptMessage(
      encodedRumor,
      publicKey: receiverPubkey,
      privateKey: signer.privateKey,
      compressionAlgorithm: compressionAlgorithm,
    );

    final createdAt = randomDateBefore().microsecondsSinceEpoch;

    if (currentUserMasterPubkey.isEmpty) {
      throw UserMasterPubkeyNotFoundException();
    }

    return EventMessage.fromData(
      kind: kind,
      signer: signer,
      createdAt: createdAt,
      content: encryptedRumor,
      tags: [
        MasterPubkeyTag(value: currentUserMasterPubkey).toTag(),
        if (compressionAlgorithm != CompressionAlgorithm.none)
          CompressionTag(value: compressionAlgorithm.name).toTag(),
      ],
    );
  }

  @override
  Future<EventMessage> decodeSeal(
    String content,
    String senderPubkey,
    String privateKey, {
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
