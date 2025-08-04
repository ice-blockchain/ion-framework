// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/push_notifications/data/models/ion_connect_push_data_payload.f.dart';
import 'package:ion/app/features/push_notifications/providers/notification_data_parser_provider.r.dart';
import 'package:ion/app/features/user_profile/database/dao/user_delegation_dao.m.dart';
import 'package:ion/app/features/user_profile/database/dao/user_metadata_dao.m.dart';
import 'package:ion/app/features/user_profile/providers/user_profile_database_provider.r.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/services/uuid/uuid.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final backgroundContainer = ProviderContainer(
    observers: [Logger.talkerRiverpodObserver],
  );

  final notificationsService =
      await backgroundContainer.read(localNotificationsServiceProvider.future);

  IonConnect.initialize(null);

  if (message.notification != null) {
    backgroundContainer.dispose();
    return;
  }

  final data = await IonConnectPushDataPayload.fromEncoded(
    message.data,
    unwrapGift: (eventMassage) async {
      final sharedPreferencesFoundation =
          await backgroundContainer.read(sharedPreferencesFoundationProvider.future);
      final currentUserPubkeyFromStorage =
          await sharedPreferencesFoundation.getString(CurrentPubkeySelector.persistenceKey);

      final messageContainer = ProviderContainer(
        observers: [Logger.talkerRiverpodObserver],
        overrides: [
          currentPubkeySelectorProvider.overrideWith(
            () {
              if (currentUserPubkeyFromStorage == null) {
                throw UserMasterPubkeyNotFoundException();
              }

              return _BackgroundCurrentPubkeySelector(currentUserPubkeyFromStorage);
            },
          ),
          currentUserIonConnectEventSignerProvider.overrideWith((ref) async {
            final savedIdentityKeyName =
                await ref.watch(currentIdentityKeyNameStoreProvider.future);
            if (savedIdentityKeyName != null) {
              return ref.watch(ionConnectEventSignerProvider(savedIdentityKeyName).future);
            }
            return null;
          }),
          encryptedMessageServiceProvider.overrideWith((ref) async {
            final eventSigner = await ref.watch(currentUserIonConnectEventSignerProvider.future);

            if (eventSigner == null) {
              throw EventSignerNotFoundException();
            }

            if (currentUserPubkeyFromStorage == null) {
              throw UserMasterPubkeyNotFoundException();
            }

            return EncryptedMessageService(
              eventSigner: eventSigner,
              currentUserPubkey: currentUserPubkeyFromStorage,
            );
          }),
        ],
      );
      try {
        final eventSigner =
            await messageContainer.read(currentUserIonConnectEventSignerProvider.future);
        final sealService = await messageContainer.read(ionConnectSealServiceProvider.future);
        final giftWrapService =
            await messageContainer.read(ionConnectGiftWrapServiceProvider.future);

        if (eventSigner == null) {
          throw EventSignerNotFoundException();
        }

        final giftUnwrapService = GiftUnwrapService(
          sealService: sealService,
          giftWrapService: giftWrapService,
          privateKey: eventSigner.privateKey,
          verifyDelegationCallback: (String pubkey) async {
            return messageContainer.read(userDelegationDaoProvider).get(pubkey);
          },
        );

        final event = await giftUnwrapService.unwrap(eventMassage);

        final userMetadata =
            await messageContainer.read(userMetadataDaoProvider).get(event.masterPubkey);

        return (event, userMetadata);
      } catch (e) {
        Logger.error('Background push notification unwrapGift: $e');
        return (null, null);
      } finally {
        // Close database connection which we use inside providers to prevent isolate leaks
        await messageContainer.read(userProfileDatabaseProvider).close();
        messageContainer.dispose();
      }
    },
  );

  final parser = await backgroundContainer.read(notificationDataParserProvider.future);
  final parsedData = await parser.parse(
    data,
    getFundsRequestData: (eventMessage) =>
        backgroundContainer.read(fundsRequestDisplayDataProvider(eventMessage).future),
    getTransactionData: (eventMessage) =>
        backgroundContainer.read(transactionDisplayDataProvider(eventMessage).future),
  );

  final title = parsedData?.title ?? message.notification?.title;
  final body = parsedData?.body ?? message.notification?.body;

  if (title == null || body == null) {
    backgroundContainer.dispose();
    return;
  }

  await notificationsService.showNotification(
    id: generateUuid().hashCode,
    title: title,
    body: body,
    payload: jsonEncode(message.data),
  );

  backgroundContainer.dispose();
}

void initFirebaseMessagingBackgroundHandler() {
  if (!kIsWeb && Platform.isAndroid) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

// Wrapper for CurrentPubkeySelector to be used in provider containers with overrideWith
class _BackgroundCurrentPubkeySelector extends CurrentPubkeySelector {
  _BackgroundCurrentPubkeySelector(this._pubkey);

  final String _pubkey;

  @override
  String build() {
    return _pubkey;
  }
}
