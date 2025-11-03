// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_expiration.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_transaction_to_relay_service.r.g.dart';

typedef MasterPubkeyWithDeviceKeys = ({String masterPubkey, List<String> devicePubkeys});
typedef PubkeyPair = ({String masterPubkey, String devicePubkey});

@riverpod
Future<SendTransactionToRelayService> sendTransactionToRelayService(Ref ref) async {
  final sealService = await ref.watch(ionConnectSealServiceProvider.future);
  final wrapService = await ref.watch(ionConnectGiftWrapServiceProvider.future);
  final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);

  if (eventSigner == null) {
    throw EventSignerNotFoundException();
  }

  return SendTransactionToRelayService(
    eventSigner: eventSigner,
    sealService: sealService,
    wrapService: wrapService,
    env: ref.watch(envProvider.notifier),
    ionConnectNotifier: ref.watch(ionConnectNotifierProvider.notifier),
  );
}

class SendTransactionToRelayService {
  SendTransactionToRelayService({
    required this.env,
    required this.wrapService,
    required this.sealService,
    required this.eventSigner,
    required this.ionConnectNotifier,
  });

  final Env env;
  final EventSigner eventSigner;
  final IonConnectNotifier ionConnectNotifier;
  final IonConnectSealService sealService;
  final IonConnectGiftWrapService wrapService;

  Future<EventMessage> sendTransactionEntity({
    required EventMessage Function(String devicePubkey, String masterPubkey) createEventMessage,
    required MasterPubkeyWithDeviceKeys senderPubkeys,
    required MasterPubkeyWithDeviceKeys receiverPubkeys,
  }) async {
    try {
      final pubkeyCombinations = <PubkeyPair>[
        ...receiverPubkeys.devicePubkeys.map(
          (receiverPubkey) => (
            masterPubkey: receiverPubkeys.masterPubkey,
            devicePubkey: receiverPubkey,
          ),
        ),
        ...senderPubkeys.devicePubkeys.map(
          (senderPubkey) => (
            masterPubkey: senderPubkeys.masterPubkey,
            devicePubkey: senderPubkey,
          ),
        ),
      ];

      final event = createEventMessage(eventSigner.publicKey, senderPubkeys.masterPubkey);

      final masterPubkeyToGiftWrap = await pubkeyCombinations.map((pubkeys) async {
        final (:masterPubkey, :devicePubkey) = pubkeys;

        final giftWrap = await _createGiftWrap(
          signer: eventSigner,
          eventMessage: event,
          receiverPubkey: devicePubkey,
          receiverMasterPubkey: masterPubkey,
          kind: event.kind,
        );

        return (masterPubkey, giftWrap);
      }).wait;

      final groupedEvents = <String, List<EventMessage>>{};
      for (final (masterPubkey, giftWrap) in masterPubkeyToGiftWrap) {
        groupedEvents.putIfAbsent(masterPubkey, () => []).add(giftWrap);
      }

      await Future.wait(
        groupedEvents.entries.map((entry) async {
          final masterPubkey = entry.key;
          final events = entry.value;

          await ionConnectNotifier.sendEvents(
            events,
            cache: false,
            actionSource: ActionSourceUser(masterPubkey, anonymous: true),
          );
        }),
      );

      return event;
    } catch (e) {
      throw SendEventException(e.toString());
    }
  }

  Future<EventMessage> _createGiftWrap({
    required String receiverPubkey,
    required String receiverMasterPubkey,
    required EventSigner signer,
    required EventMessage eventMessage,
    int kind = EncryptedDirectMessageEntity.kind,
  }) async {
    final randomCreatedAt = randomDateBefore();

    final expirationTag = EntityExpiration(
      value: randomCreatedAt
          .add(Duration(hours: env.get<int>(EnvVariable.GIFT_WRAP_EXPIRATION_HOURS)))
          .microsecondsSinceEpoch,
    ).toTag();

    final seal = await sealService.createSeal(
      eventMessage,
      signer,
      receiverPubkey,
    );

    final wrap = await wrapService.createWrap(
      event: seal,
      randomCreatedAt: randomCreatedAt,
      contentKinds: [kind.toString()],
      receiverPubkey: receiverPubkey,
      receiverMasterPubkey: receiverMasterPubkey,
      expirationTag: expirationTag,
    );

    return wrap;
  }
}
