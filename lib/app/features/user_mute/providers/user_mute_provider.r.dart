// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/pubkey_tag.f.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/mute_set.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user_mute/model/database/user_mute_database.m.dart';
import 'package:ion/app/features/user_mute/model/entities/user_mute_entity.f.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/date.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_mute_provider.r.g.dart';

@riverpod
Stream<UserMuteEntity?> userMute(Ref ref) {
  final userMuteEventDao = ref.watch(userMuteEventDaoProvider);

  return userMuteEventDao.watchLatestMuteEvent().map((event) {
    if (event == null) return null;
    return UserMuteEntity.fromEventMessage(event);
  });
}

@riverpod
Future<UserMuteService> userMuteService(Ref ref) async {
  final muteSetEntity = ref.watch(cachedMuteSetProvider);
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final eventSigner = ref.watch(currentUserIonConnectEventSignerProvider).value;
  final sealService = ref.watch(ionConnectSealServiceProvider).value;
  final userMuteEventDao = ref.watch(userMuteEventDaoProvider);
  final wrapService = ref.watch(ionConnectGiftWrapServiceProvider).value;
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final devicePubkeysProvider = ref.watch(conversationPubkeysProvider.notifier);
  final encryptedMessageService = await ref.watch(encryptedMessageServiceProvider.future);

  return UserMuteService(
    eventSigner: eventSigner,
    sealService: sealService,
    wrapService: wrapService,
    muteSetEntity: muteSetEntity,
    ionConnectNotifier: ionConnectNotifier,
    userMuteEventDao: userMuteEventDao,
    devicePubkeysProvider: devicePubkeysProvider,
    encryptedMessageService: encryptedMessageService,
    currentUserMasterPubkey: currentUserMasterPubkey,
  );
}

class UserMuteService {
  UserMuteService({
    required this.eventSigner,
    required this.sealService,
    required this.wrapService,
    required this.muteSetEntity,
    required this.ionConnectNotifier,
    required this.userMuteEventDao,
    required this.devicePubkeysProvider,
    required this.currentUserMasterPubkey,
    required this.encryptedMessageService,
  });

  final EventSigner? eventSigner;
  final MuteSetEntity? muteSetEntity;
  final String? currentUserMasterPubkey;
  final UserMuteEventDao userMuteEventDao;
  final IonConnectSealService? sealService;
  final IonConnectNotifier ionConnectNotifier;
  final IonConnectGiftWrapService? wrapService;
  final ConversationPubkeys devicePubkeysProvider;
  final EncryptedMessageService encryptedMessageService;

  Future<void> checkMuteMigrated() async {
    try {
      final wrapMuteExists = await userMuteEventDao.hasAnyMuteEvent();

      if (wrapMuteExists) {
        Logger.log('Mute migration not needed, wrap mute event exists');
        return;
      }

      Logger.log('Starting mute migration from mute set to wrap events');

      final conversationIds = <String>[];

      if (muteSetEntity != null && muteSetEntity!.data.masterPubkeys.isNotEmpty) {
        conversationIds.addAll(muteSetEntity!.data.masterPubkeys);
      }

      await sendUserMuteEvent(conversationIds);
      Logger.log('Mute migration completed successfully');
    } catch (e, st) {
      Logger.error(e, stackTrace: st);
    }
  }

  Future<void> sendUserMuteEvent(List<String> mutedUsers) async {
    if (eventSigner == null) throw EventSignerNotFoundException();
    if (currentUserMasterPubkey == null) throw UserMasterPubkeyNotFoundException();
    if (sealService == null || wrapService == null) return;

    final participantsMasterPubkeys = [currentUserMasterPubkey!];
    final participantsPubkeysMap =
        await devicePubkeysProvider.fetchUsersKeys(participantsMasterPubkeys);
    final createdAt = DateTime.now();

    await Future.wait(
      participantsMasterPubkeys.map((receiverMasterPubkey) async {
        final pubkeyDevices = participantsPubkeysMap[receiverMasterPubkey];
        if (pubkeyDevices == null) throw UserPubkeyNotFoundException(receiverMasterPubkey);

        for (final receiverPubkey in pubkeyDevices) {
          final eventMessage = await EventMessage.fromData(
            content: '',
            signer: eventSigner!,
            kind: UserMuteEntity.kind,
            createdAt: createdAt.microsecondsSinceEpoch,
            tags: [
              MasterPubkeyTag(value: currentUserMasterPubkey).toTag(),
              ...mutedUsers.map((id) => PubkeyTag(value: id).toTag()),
            ],
          );

          final seal = await sealService!.createSeal(eventMessage, eventSigner!, receiverPubkey);
          final randomCreatedAt = randomDateBefore();
          final giftWrap = await wrapService!.createWrap(
            event: seal,
            receiverPubkey: receiverPubkey,
            randomCreatedAt: randomCreatedAt,
            receiverMasterPubkey: currentUserMasterPubkey!,
            contentKinds: [UserMuteEntity.kind.toString()],
          );

          await userMuteEventDao.add(eventMessage);

          try {
            await ionConnectNotifier.sendEvent(
              giftWrap,
              cache: false,
              actionSource: ActionSourceUser(currentUserMasterPubkey!, anonymous: true),
            );
          } catch (_) {
            final entity = UserMuteEntity.fromEventMessage(eventMessage);
            await userMuteEventDao.remove(entity.toEventReference());
          }
        }
      }),
    );
  }
}
