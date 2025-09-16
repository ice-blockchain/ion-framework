// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/compression_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_logger.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:nip44/nip44.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gift_unwrap_service_provider.r.g.dart';

typedef VerifyDelegationCallback = Future<UserDelegationEntity?> Function(String pubkey);

class GiftUnwrapService {
  GiftUnwrapService({
    required String privateKey,
    required IonConnectSealService sealService,
    required IonConnectGiftWrapService giftWrapService,
    required VerifyDelegationCallback verifyDelegationCallback,
    this.logger,
  })  : _privateKey = privateKey,
        _sealService = sealService,
        _giftWrapService = giftWrapService,
        _verifyDelegationCallback = verifyDelegationCallback;

  final String _privateKey;
  final IonConnectLogger? logger;
  final IonConnectSealService _sealService;
  final IonConnectGiftWrapService _giftWrapService;
  final VerifyDelegationCallback _verifyDelegationCallback;

  Future<EventMessage> unwrap(EventMessage giftWrap, {bool validate = true}) async {
    try {
      final compressionTag = giftWrap.tags.firstWhereOrNull(
        (tag) => tag[0] == CompressionTag.tagName,
      );
      final compression = compressionTag != null
          ? CompressionTag.fromTag(compressionTag).algorithm
          : CompressionAlgorithm.none;

      final (rumor, seal) = await unwrapGiftSharedIsolate.compute(unwrapGiftFn, [
        _giftWrapService,
        _sealService,
        _privateKey,
        giftWrap.content,
        giftWrap.pubkey,
        logger,
        compression,
      ]);

      if (validate) {
        final sealDelegation = await _verifyDelegationCallback(seal.masterPubkey);

        if (sealDelegation == null || !sealDelegation.data.validate(seal)) {
          throw DecodeE2EMessageException(giftWrap.id);
        }
      }

      return rumor;
    } catch (e) {
      throw DecodeE2EMessageException(giftWrap.id, error: e);
    }
  }
}

@riverpod
Future<GiftUnwrapService> giftUnwrapService(Ref ref) async {
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);
  final sealService = await ref.watch(ionConnectSealServiceProvider.future);
  final giftWrapService = await ref.watch(ionConnectGiftWrapServiceProvider.future);

  if (eventSigner == null) {
    throw EventSignerNotFoundException();
  }

  return GiftUnwrapService(
    sealService: sealService,
    giftWrapService: giftWrapService,
    privateKey: eventSigner.privateKey,
    verifyDelegationCallback: (pubkey) async {
      return ref.read(userDelegationProvider(pubkey).future);
    },
  );
}

final unwrapGiftSharedIsolate = IsolateManager.createShared(
  useWorker: true,
  workerMappings: {
    unwrapGiftFn: 'unwrapGiftFn',
  },
);

@pragma('vm:entry-point')
Future<(EventMessage, EventMessage)> unwrapGiftFn(List<dynamic> args) async {
  final giftWrapService = args[0] as IonConnectGiftWrapService;
  final sealService = args[1] as IonConnectSealService;
  final privateKey = args[2] as String;
  final content = args[3] as String;
  final senderPubkey = args[4] as String;
  final logger = args[5] as IonConnectLogger?;
  final compressionAlgorithm = args[6] as CompressionAlgorithm;

  // It is isolated, so we need to initialize it again for sign verification
  IonConnect.initialize(logger);

  final seal = await giftWrapService.decodeWrap(
    privateKey: privateKey,
    content: content,
    senderPubkey: senderPubkey,
    compressionAlgorithm: compressionAlgorithm,
  );

  final compressionTag = seal.tags.firstWhereOrNull(
    (tag) => tag[0] == CompressionTag.tagName,
  );

  final compression = compressionTag != null
      ? CompressionTag.fromTag(compressionTag).algorithm
      : compressionAlgorithm;

  final rumor = await sealService.decodeSeal(
    seal.content,
    seal.pubkey,
    privateKey,
    compressionAlgorithm: compression,
  );

  // Check if:
  // 1. The seal is valid (validated signature)
  // 2. The seal pubkey is the same as the rumor pubkey
  // 3. The seal masterPubkey is the same as the rumor masterPubkey
  if (await seal.validate() &&
      seal.pubkey == rumor.pubkey &&
      seal.masterPubkey == rumor.masterPubkey) {
    return (rumor, seal);
  } else {
    throw DecodeE2EMessageException(rumor.id);
  }
}
