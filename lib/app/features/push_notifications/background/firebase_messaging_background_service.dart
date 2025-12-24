// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/push_notifications/data/models/ion_connect_push_data_payload.f.dart';
import 'package:ion/app/features/push_notifications/providers/app_translations_provider.m.dart';
import 'package:ion/app/features/push_notifications/providers/notification_data_parser_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/providers/coins_provider.r.dart';
import 'package:ion/app/services/ion_connect/encrypted_message_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/logger/logger_initializer.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// At file top (module-level)
Raw<IONIdentity>? _bgIonIdentity;
Completer<Raw<IONIdentity>>? _bgIonInit;

Override _backgroundIonIdentityOverrideSingleton() {
  return ionIdentityProvider.overrideWith((ref) async {
    // Reuse if already created
    if (_bgIonIdentity != null) return _bgIonIdentity!;
    // Coalesce concurrent inits
    if (_bgIonInit != null) return _bgIonInit!.future;

    final c = Completer<Raw<IONIdentity>>();
    _bgIonInit = c;
    try {
      final env = ref.watch(envProvider.notifier);
      final appId = env.get<String>(
        Platform.isAndroid ? EnvVariable.ION_ANDROID_APP_ID : EnvVariable.ION_IOS_APP_ID,
      );
      final origin = env.get<String>(EnvVariable.ION_ORIGIN);

      final cfg = IONIdentityConfig(appId: appId, origin: origin);
      final client = IONIdentity.createDefault(config: cfg);
      await client.init();

      _bgIonIdentity = client;
      c.complete(client);
      return client;
    } catch (e, st) {
      Logger.error(
        e,
        stackTrace: st,
        message: '☁️ [BG] ionIdentity singleton: init FAILED',
      );
      c.completeError(e, st);
      rethrow;
    } finally {
      _bgIonInit = null;
    }
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final backgroundContainer = ProviderContainer(
    observers: [Logger.talkerRiverpodObserver],
  );
  LoggerInitializer.initialize(backgroundContainer);

  Logger.log('☁️ Background push notification received: ${message.toMap()}');

  final notificationsService =
      await backgroundContainer.read(localNotificationsServiceProvider.future);

  IonConnect.initialize(null);

  // Resolve current user's master pubkey once for this handler
  final sharedPreferencesFoundation =
      await backgroundContainer.read(sharedPreferencesFoundationProvider.future);
  final currentUserPubkeyFromStorage =
      await sharedPreferencesFoundation.getString(CurrentPubkeySelector.persistenceKey);

  Logger.log(
    '☁️ Background push notification currentUserPubkeyFromStorage: $currentUserPubkeyFromStorage',
  );

  // Resolve saved identity key name for background containers that need it
  final savedIdentityKeyName =
      await backgroundContainer.read(currentIdentityKeyNameStoreProvider.future);

  if (message.notification != null) {
    backgroundContainer.dispose();
    return;
  }

  final data = await IonConnectPushDataPayload.fromEncoded(
    message.data,
    unwrapGift: (eventMessage) async {
      final messageContainer = ProviderContainer(
        observers: [Logger.talkerRiverpodObserver],
        overrides: [
          _backgroundCurrentPubkeyOverride(currentUserPubkeyFromStorage),
          _backgroundIonIdentityOverrideSingleton(),
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
          verifyDelegationCallback: (String masterPubkey) async {
            Logger.log(
              '☁️ Background push notification verifyDelegation for pubkey: $masterPubkey',
            );

            final delegation = await messageContainer.read(
              cachedUserDelegationProvider(masterPubkey).future,
            );

            Logger.log('☁️ Background push notification verifyDelegation result: $delegation');
            return delegation;
          },
        );

        final event = await giftUnwrapService.unwrap(eventMessage, validate: false);
        Logger.log('☁️ Background push notification unwrap event: $event');

        final cachedEntity = await messageContainer
            .read(
              ionConnectDatabaseCacheProvider.notifier,
            )
            .get(
              ReplaceableEventReference(
                masterPubkey: event.masterPubkey,
                kind: UserMetadataEntity.kind,
              ).toString(),
            );

        final userMetadata = cachedEntity as UserMetadataEntity?;

        Logger.log('☁️ Background push notification userMetadata: $userMetadata');
        return (event, userMetadata);
      } catch (e, st) {
        Logger.error(
          e,
          stackTrace: st,
          message: '☁️ Background push notification unwrapGift',
        );
        return (null, null);
      } finally {
        // Close ion_cache_database connection to prevent isolate leaks
        try {
          final cacheService =
              await messageContainer.read(ionConnectPersistentCacheServiceProvider.future);
          if (cacheService is IonConnectCacheServiceDriftImpl) {
            await cacheService.attachedDatabase.close();
          }
        } catch (e, st) {
          Logger.error(
            e,
            stackTrace: st,
            message: '☁️ Background push notification close db error',
          );
        }
        messageContainer.dispose();
      }
    },
  );

  // Skip notification if it's user's own gift wrap
  if (_shouldSkipOwnGiftWrap(data: data, currentPubkey: currentUserPubkeyFromStorage)) {
    Logger.log('☁️ Background push notification: Skipping own gift wrap');
    backgroundContainer.dispose();
    return;
  }

  // Skip notifications for self-interactions (e.g., quoting/reposting own content)
  if (currentUserPubkeyFromStorage != null &&
      data.isSelfInteraction(currentPubkey: currentUserPubkeyFromStorage)) {
    Logger.log('☁️ Background push notification: Skipping self-interaction');
    backgroundContainer.dispose();
    return;
  }

  // Skip notifications from muted users or muted conversations
  if (await _shouldSkipMutedNotification(
    data: data,
    currentPubkey: currentUserPubkeyFromStorage,
    backgroundContainer: backgroundContainer,
  )) {
    Logger.log('☁️ Background push notification: Skipping muted user/conversation');
    backgroundContainer.dispose();
    return;
  }

  // Build a dedicated container for parsing that has the current pubkey override,
  // so providers that need it (e.g., wallets DB) can resolve in a background isolate.
  final pushTranslatorBgOverride = pushTranslatorProvider.overrideWith((ref) async {
    // read saved language code safely in background
    final prefs = await ref.watch(sharedPreferencesFoundationProvider.future);
    final langCode = await prefs.getString(AppLocale.localePersistenceKey) ?? 'en';

    final repo = await ref.watch(configRepositoryProvider.future);
    return Translator(
      translationsRepository: repo,
      locale: Locale(langCode),
    );
  });
  final coinIdForOverride = _extractCoinIdFromPaymentRequestedTag(data.decryptedEvent);
  final parseContainer = ProviderContainer(
    observers: [Logger.talkerRiverpodObserver],
    overrides: [
      _backgroundCurrentPubkeyOverride(currentUserPubkeyFromStorage),
      _backgroundIdentityKeyNameOverride(savedIdentityKeyName),
      _backgroundIonIdentityOverrideSingleton(),
      pushTranslatorBgOverride,
      if (coinIdForOverride != null)
        coinByIdProvider(coinIdForOverride).overrideWith(
          (ref) async => ref.read(coinsRepositoryProvider).getCoinById(coinIdForOverride),
        ),
    ],
  );

  NotificationParsedData? parsedData;
  try {
    final parser = await parseContainer.read(notificationDataParserProvider.future);
    parsedData = await parser.parse(
      data,
      getFundsRequestData: (eventMessage) =>
          parseContainer.read(fundsRequestDisplayDataProvider(eventMessage).future),
      getTransactionData: (eventMessage) =>
          parseContainer.read(transactionDisplayDataProvider(eventMessage).future),
      getRelatedEntity: (eventReference) async {
        try {
          final cacheService =
              await parseContainer.read(ionConnectPersistentCacheServiceProvider.future);
          final parser = parseContainer.read(eventParserProvider);

          final cacheKey = eventReference.toString();
          final result = await cacheService.get(cacheKey);
          if (result == null) {
            return null;
          }

          final entity = parser.parse(result.eventMessage);
          return entity;
        } catch (e, st) {
          Logger.error(
            e,
            stackTrace: st,
            message: '☁️ Background getRelatedEntity failed',
          );
          return null;
        }
      },
    );
  } catch (e, st) {
    Logger.error(
      e,
      stackTrace: st,
      message: '☁️ Background parser.parse failed',
    );
  } finally {
    // Close DBs opened through providers in this container to avoid isolate leaks.
    try {
      await parseContainer.read(walletsDatabaseProvider).close();
    } catch (_) {}
    parseContainer.dispose();
  }

  final title = parsedData?.title ?? message.notification?.title;
  final body = parsedData?.body ?? message.notification?.body;

  if (title == null || body == null) {
    backgroundContainer.dispose();
    return;
  }

  final avatar = parsedData?.avatar;
  final media = parsedData?.media;
  final groupKey = parsedData?.groupKey;

  await notificationsService.showNotification(
    title: title,
    body: body,
    payload: jsonEncode(message.data),
    icon: avatar,
    attachment: media,
    groupKey: groupKey,
  );

  backgroundContainer.dispose();
}

/// Check if notification should be skipped because user/conversation is muted
FutureOr<bool> _shouldSkipMutedNotification({
  required IonConnectPushDataPayload data,
  required String? currentPubkey,
  required ProviderContainer backgroundContainer,
}) async {
  // Check if this is a gift wrap (chat) notification
  if (data.event.kind != IonConnectGiftWrapEntity.kind) {
    return false;
  }

  if (currentPubkey == null) {
    return false;
  }

  // Get the sender's pubkey from decrypted event
  final decryptedEvent = data.decryptedEvent;
  if (decryptedEvent == null) {
    return false;
  }

  final senderPubkey = decryptedEvent.masterPubkey;

  // Create a container to check muted users
  final mutedCheckContainer = ProviderContainer(
    observers: [Logger.talkerRiverpodObserver],
    overrides: [
      _backgroundCurrentPubkeyOverride(currentPubkey),
    ],
  );

  try {
    // Check if sender is muted
    // For one-to-one chats it is enough to check if sender is muted
    final mutedUsers = await mutedCheckContainer.read(mutedUsersProvider.future);
    if (mutedUsers.contains(senderPubkey)) {
      return true;
    }

    return false;
  } finally {
    mutedCheckContainer.dispose();
  }
}

/// Check if the gift wrap notification should be skipped because it's from the current user
bool _shouldSkipOwnGiftWrap({
  required IonConnectPushDataPayload data,
  required String? currentPubkey,
}) {
  if (currentPubkey == null) {
    return true;
  }

  if (data.event.kind == IonConnectGiftWrapEntity.kind) {
    final decryptedEvent = data.decryptedEvent;
    if (decryptedEvent != null) {
      return decryptedEvent.masterPubkey == currentPubkey;
    }
  }

  return false;
}

// Reusable override for background containers that need the current master pubkey.
Override _backgroundCurrentPubkeyOverride(String? storedPubkey) {
  Logger.log('☁️ Background push notification storedPubkey: $storedPubkey');
  if (storedPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }
  return currentPubkeySelectorProvider.overrideWith(
    () => _BackgroundCurrentPubkeySelector(storedPubkey),
  );
}

// Reusable override for background containers that need the current identity key name (username)
Override _backgroundIdentityKeyNameOverride(String? savedIdentityKeyName) {
  Logger.log('☁️ Background push notification savedIdentityKeyName: $savedIdentityKeyName');
  if (savedIdentityKeyName == null) {
    throw const CurrentUserNotFoundException();
  }
  return currentIdentityKeyNameSelectorProvider.overrideWith(
    () => _BackgroundIdentityKeyNameSelector(savedIdentityKeyName),
  );
}

String? _extractCoinIdFromPaymentRequestedTag(EventMessage? decrypted) {
  if (decrypted == null) return null;
  try {
    final tag = decrypted.tags.firstWhere(
      (t) => t.isNotEmpty && t.first == ReplaceablePrivateDirectMessageData.paymentRequestedTagName,
      orElse: () => const [],
    );
    if (tag.length < 2) return null;

    final prEventJson = jsonDecode(tag[1]) as Map<String, dynamic>;
    final contentStr = prEventJson['content'] as String?;
    if (contentStr == null) return null;

    final content = jsonDecode(contentStr) as Map<String, dynamic>;
    return content['assetId'] as String?;
  } catch (_) {
    return null;
  }
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

class _BackgroundIdentityKeyNameSelector extends CurrentIdentityKeyNameSelector {
  _BackgroundIdentityKeyNameSelector(this._identityKeyName);

  final String _identityKeyName;

  @override
  String build() {
    return _identityKeyName;
  }
}
