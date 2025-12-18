// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/bookmarks_notifier.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user_archive/model/database/user_archive_database.m.dart';
import 'package:ion/app/features/user_archive/model/entities/user_archive_entity.f.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/date.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_archive_provider.r.g.dart';

@riverpod
Stream<UserArchiveEntity?> userArchive(Ref ref) {
  final userArchiveEventDao = ref.watch(userArchiveEventDaoProvider);
  final userArchiveEvent = userArchiveEventDao.watchLatestArchiveEvent();

  return userArchiveEvent.map((event) {
    final entity = event == null ? null : UserArchiveEntity.fromEventMessage(event);
    return entity;
  });
}

@riverpod
Future<UserArchiveService> userArchiveService(Ref ref) async {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final eventSigner = ref.watch(currentUserIonConnectEventSignerProvider).value;
  final sealService = ref.watch(ionConnectSealServiceProvider).value;
  final userArchiveEventDao = ref.watch(userArchiveEventDaoProvider);
  final wrapService = ref.watch(ionConnectGiftWrapServiceProvider).value;
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final devicePubkeysProvider = ref.watch(conversationPubkeysProvider.notifier);
  final bookmarksProvider = await ref.watch(currentUserChatBookmarksDataProvider.future);
  final encryptedMessageService = await ref.watch(encryptedMessageServiceProvider.future);

  return UserArchiveService(
    eventSigner: eventSigner,
    sealService: sealService,
    wrapService: wrapService,
    archiveBookmarks: bookmarksProvider,
    ionConnectNotifier: ionConnectNotifier,
    userArchiveEventDao: userArchiveEventDao,
    devicePubkeysProvider: devicePubkeysProvider,
    encryptedMessageService: encryptedMessageService,
    currentUserMasterPubkey: currentUserMasterPubkey,
  );
}

class UserArchiveService {
  UserArchiveService({
    required this.eventSigner,
    required this.sealService,
    required this.wrapService,
    required this.archiveBookmarks,
    required this.ionConnectNotifier,
    required this.userArchiveEventDao,
    required this.devicePubkeysProvider,
    required this.currentUserMasterPubkey,
    required this.encryptedMessageService,
  });

  final EventSigner? eventSigner;
  final String? currentUserMasterPubkey;
  final BookmarksSetData? archiveBookmarks;
  final IonConnectSealService? sealService;
  final IonConnectGiftWrapService? wrapService;
  final IonConnectNotifier ionConnectNotifier;
  final UserArchiveEventDao userArchiveEventDao;
  final ConversationPubkeys devicePubkeysProvider;
  final EncryptedMessageService encryptedMessageService;

  Future<void> checkArchiveMigrated() async {
    try {
      final wrapArchiveExists = await userArchiveEventDao.hasAnyArchiveEvent();

      if (wrapArchiveExists) {
        Logger.log('Archive migration not needed, wrap archive exists');
        return;
      }

      Logger.log('Starting archive migration from bookmarks to wrap events');

      final conversationIds = <String>[];

      if (archiveBookmarks != null && archiveBookmarks!.content.isNotEmpty) {
        final decryptedContent =
            await encryptedMessageService.decryptMessage(archiveBookmarks!.content);

        final decryptedTags = (jsonDecode(decryptedContent) as List)
            .map((e) => (e as List).map((s) => s.toString()).toList())
            .toList();

        final conversations = decryptedTags.map(ConversationIdentifier.fromTag).toSet();

        conversationIds.addAll(conversations.map((e) => e.value));
      }

      await sendUserArchiveEvent(conversationIds);
      Logger.log('Archive migration completed successfully');
    } catch (e, st) {
      Logger.error(e, stackTrace: st);
    }
  }

  Future<void> sendUserArchiveEvent(List<String> conversationsIds) async {
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
            kind: UserArchiveEntity.kind,
            createdAt: createdAt.microsecondsSinceEpoch,
            tags: [
              ...conversationsIds.map((id) => ConversationIdentifier(value: id).toTag()),
              MasterPubkeyTag(value: currentUserMasterPubkey).toTag(),
            ],
          );

          final seal = await sealService!.createSeal(eventMessage, eventSigner!, receiverPubkey);
          final randomCreatedAt = randomDateBefore();
          final giftWrap = await wrapService!.createWrap(
            event: seal,
            receiverPubkey: receiverPubkey,
            randomCreatedAt: randomCreatedAt,
            receiverMasterPubkey: currentUserMasterPubkey!,
            contentKinds: [UserArchiveEntity.kind.toString()],
          );

          await userArchiveEventDao.add(eventMessage);

          try {
            await ionConnectNotifier.sendEvent(
              giftWrap,
              cache: false,
              actionSource: ActionSourceUser(currentUserMasterPubkey!, anonymous: true),
            );
          } catch (_) {
            final entity = UserArchiveEntity.fromEventMessage(eventMessage);
            await userArchiveEventDao.remove(entity.toEventReference());
          }
        }
      }),
    );
  }
}
