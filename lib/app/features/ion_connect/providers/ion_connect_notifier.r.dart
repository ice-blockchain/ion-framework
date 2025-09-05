// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart' as ion;
import 'package:ion/app/features/ion_connect/ion_connect.dart' hide requestEvents;
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/disliked_relay_urls_collection.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata_builder.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/long_living_subscription_relay_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_auth_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/model/badges/badge_definition.f.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/providers/relays/current_user_write_relay.r.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/uuid/uuid.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_notifier.r.g.dart';

const _defaultTimeout = Duration(seconds: 30);

@riverpod
class IonConnectNotifier extends _$IonConnectNotifier {
  @override
  FutureOr<void> build() {}

  Future<List<IonConnectEntity>?> _sendEvents(
    List<EventMessage> events, {
    ActionSource actionSource = const ActionSourceCurrentUser(),
    bool cache = true,
  }) async {
    _warnSendIssues(events);

    final sessionId = generateUuid();
    final eventIds = events.map((e) => e.id).toList();
    final stopwatch = Stopwatch()..start();

    Logger.log(
      '[SESSION-START] Starting session $sessionId with events: $eventIds, source: $actionSource',
    );

    final dislikedRelaysUrls = <String>{};

    IonConnectRelay? triedRelay;
    try {
      return withRetry(
        ({error}) async {
          triedRelay = null;
          final relaysUserMap = await ref.read(relayPickerProvider.notifier).getActionSourceRelays(
                actionSource,
                actionType: ActionType.write,
                dislikedUrls: DislikedRelayUrlsCollection(dislikedRelaysUrls),
              );
          for (final relaysUserMap in relaysUserMap.entries) {
            triedRelay = relaysUserMap.key;

            _handleWriteRelay(actionSource, relaysUserMap.key.url);

            await ref
                .read(relayAuthProvider(relaysUserMap.key))
                .handleRelayAuthOnAction(actionSource: actionSource, error: error);

            await _sendEventsToRelay(events, relay: relaysUserMap.key);

            if (cache) {
              return events.map(_parseAndCache).toList();
            }
          }

          return null;
        },
        retryWhen: (error) {
          // Retry in case of any error except when no relay is selected.
          // This is to avoid retrying when there are no available relays left or they are not assigned (registration).
          final triedRelayUrl =
              error is RelayUnreachableException ? error.relayUrl : triedRelay?.url;
          Logger.log(
            '[SESSION-RETRY] Session $sessionId - $triedRelayUrl retry: ${triedRelayUrl != null} for error: $error',
          );
          return triedRelayUrl != null;
        },
        onRetry: (error) async {
          final triedRelayUrl =
              error is RelayUnreachableException ? error.relayUrl : triedRelay?.url;
          if (triedRelayUrl != null && !RelayAuthService.isRelayAuthError(error)) {
            Logger.error(
              error ?? '',
              message: '[SESSION-ERROR] Session $sessionId - $triedRelayUrl failed: $error',
            );
            Logger.log(
              '[SESSION-DISLIKE] Session $sessionId - $triedRelayUrl added to disliked relays',
            );
            dislikedRelaysUrls.add(triedRelayUrl);
            if (UserRelaysManager.isRelayReadOnlyError(error)) {
              await ref
                  .read(userRelaysManagerProvider.notifier)
                  .handleCachedReadOnlyRelay(triedRelayUrl);
            }
          }
          Logger.log(
            '[SESSION-RETRY] Session $sessionId retry attempt at ${stopwatch.elapsedMilliseconds}ms',
          );
        },
      );
    } catch (e) {
      Logger.error(e, message: '[SESSION-ERROR] Session $sessionId failed: $e');
      rethrow;
    } finally {
      stopwatch.stop();
      Logger.log(
        '[SESSION-COMPLETE] Session $sessionId completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<List<IonConnectEntity>?> sendEvents(
    List<EventMessage> events, {
    ActionSource actionSource = const ActionSourceCurrentUser(),
    List<EventsMetadataBuilder> metadataBuilders = const [],
    bool cache = true,
  }) async {
    final eventsToSend = [...events];
    if (metadataBuilders.isNotEmpty) {
      final metadataEvents = await _buildMetadata(
        events: events,
        metadataBuilders: metadataBuilders,
      );
      eventsToSend.addAll(metadataEvents);
    }
    return _sendEvents(eventsToSend, actionSource: actionSource, cache: cache);
  }

  Future<IonConnectEntity?> sendEvent(
    EventMessage event, {
    ActionSource actionSource = const ActionSourceCurrentUser(),
    List<EventsMetadataBuilder> metadataBuilders = const [],
    bool cache = true,
  }) async {
    final result = await sendEvents(
      [event],
      cache: cache,
      actionSource: actionSource,
      metadataBuilders: metadataBuilders,
    );
    return result?.elementAtOrNull(0);
  }

  Future<List<IonConnectEntity>?> sendEntitiesData(
    List<EventSerializable> entitiesData, {
    ActionSource actionSource = const ActionSourceCurrentUser(),
    List<EventsMetadataBuilder> metadataBuilders = const [],
    List<EventMessage> additionalEvents = const [],
    bool cache = true,
  }) async {
    final events = await Future.wait(entitiesData.map(sign));
    return sendEvents(
      [...events, ...additionalEvents],
      actionSource: actionSource,
      cache: cache,
      metadataBuilders: metadataBuilders,
    );
  }

  Future<T?> sendEntityData<T extends IonConnectEntity>(
    EventSerializable entityData, {
    ActionSource actionSource = const ActionSourceCurrentUser(),
    List<EventsMetadataBuilder> metadataBuilders = const [],
    bool cache = true,
  }) async {
    final entities = await sendEntitiesData(
      [entityData],
      actionSource: actionSource,
      metadataBuilders: metadataBuilders,
      cache: cache,
    );
    return entities?.whereType<T>().elementAtOrNull(0);
  }

  Stream<EventMessage> requestEvents(
    RequestMessage requestMessage, {
    ActionType? actionType,
    ActionSource actionSource = const ActionSourceCurrentUser(),
    Stream<RelayMessage> Function(RequestMessage requestMessage, NostrRelay relay)?
        subscriptionBuilder,
    VoidCallback? onEose,
  }) async* {
    final sessionId = requestMessage.subscriptionId;
    final stopwatch = Stopwatch()..start();

    Logger.log(
      '[SESSION-REQUEST] Starting session with subscription: $sessionId source: $actionSource',
    );

    final dislikedRelaysUrls = <String>{};
    IonConnectRelay? triedRelay;
    final processedMasterPubkeys = <String>{};

    try {
      yield* withRetryStream(
        ({error}) async* {
          triedRelay = null;
          final relaysUserMap = subscriptionBuilder != null
              ? {
                  await ref.read(
                    longLivingSubscriptionRelayProvider(
                      actionSource,
                      dislikedUrls: DislikedRelayUrlsCollection(dislikedRelaysUrls),
                    ).future,
                  ): <String>{},
                }
              : await ref.read(relayPickerProvider.notifier).getActionSourceRelays(
                    actionSource is ActionSourceOptimalRelays
                        ? actionSource.copyWith(
                            masterPubkeys: actionSource.masterPubkeys
                                .where((pubkey) => !processedMasterPubkeys.contains(pubkey))
                                .toList(),
                          )
                        : actionSource,
                    actionType: actionType ?? ActionType.read,
                    dislikedUrls: DislikedRelayUrlsCollection(dislikedRelaysUrls),
                    sessionId: sessionId,
                  );

          for (final relay in relaysUserMap.entries) {
            triedRelay = relay.key;

            Logger.log(
              '[RELAY] ${relay.key.url} is chosen for reading events, $dislikedRelaysUrls',
            );

            await ref
                .read(relayAuthProvider(relay.key))
                .handleRelayAuthOnAction(actionSource: actionSource, error: error);

            requestMessage.filters.map(
              (filter) => filter.copyWith(
                authors: filter.authors == null ? null : relay.value.toList,
              ),
            );

            final events = subscriptionBuilder != null
                ? subscriptionBuilder(requestMessage, relay.key)
                : ion.requestEvents(requestMessage, relay.key);

            await for (final event in events) {
              // Note: The ion.requestEvents method automatically handles unsubscription for certain messages.
              // If the subscription needs to be retried or closed in response to a different message than those handled by ion.requestEvents,
              // then additional unsubscription logic should be implemented here.
              if (event is NoticeMessage || event is ClosedMessage) {
                throw RelayRequestFailedException(
                  relayUrl: relay.key.url,
                  event: event,
                );
              } else if (event is EventMessage) {
                yield event;
              } else if (event is EoseMessage && onEose != null) {
                onEose();
              }
            }

            if (actionSource is ActionSourceOptimalRelays) {
              processedMasterPubkeys.addAll(relay.value);
            }
          }
        },
        retryWhen: (error) {
          // Retry in case of any error except when no relay is selected.
          // This is to avoid retrying when there are no available relays left or they are not assigned (registration).
          final triedRelayUrl =
              error is RelayUnreachableException ? error.relayUrl : triedRelay?.url;
          Logger.log(
            '[SESSION-RETRY] Session $sessionId - $triedRelayUrl retry: ${triedRelayUrl != null} for error: $error',
          );
          return triedRelayUrl != null;
        },
        onRetry: (error) {
          final triedRelayUrl =
              error is RelayUnreachableException ? error.relayUrl : triedRelay?.url;
          if (triedRelayUrl != null && !RelayAuthService.isRelayAuthError(error)) {
            Logger.error(
              error ?? '',
              message: '[SESSION-ERROR] Session $sessionId - $triedRelayUrl failed: $error',
            );
            Logger.log(
              '[SESSION-DISLIKE] Session $sessionId - $triedRelayUrl added to disliked relays',
            );
            dislikedRelaysUrls.add(triedRelayUrl);
          }
          Logger.log(
            '[SESSION-RETRY] Session $sessionId retry attempt at ${stopwatch.elapsedMilliseconds}ms',
          );
        },
      );
    } catch (e) {
      Logger.error(e, message: '[SESSION-ERROR] Session $sessionId failed: $e');
      rethrow;
    } finally {
      stopwatch.stop();
      Logger.log(
        '[SESSION-COMPLETE] Session with subscription: $sessionId completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<EventMessage?> requestEvent(
    RequestMessage requestMessage, {
    ActionSource actionSource = const ActionSourceCurrentUser(),
  }) async {
    final eventsStream = requestEvents(requestMessage, actionSource: actionSource);

    final events = await eventsStream.toList();
    return events.isNotEmpty ? events.first : null;
  }

  Stream<T> requestEntities<T extends IonConnectEntity>(
    RequestMessage requestMessage, {
    ActionType? actionType,
    ActionSource actionSource = const ActionSourceCurrentUser(),
  }) async* {
    await for (final event
        in requestEvents(requestMessage, actionType: actionType, actionSource: actionSource)) {
      try {
        yield _parseAndCache(event) as T;
      } catch (error, stackTrace) {
        Logger.log('Failed to process event ${event.id}', error: error, stackTrace: stackTrace);
      }
    }
  }

  Future<T?> requestEntity<T extends IonConnectEntity>(
    RequestMessage requestMessage, {
    ActionType? actionType,
    ActionSource actionSource = const ActionSourceCurrentUser(),
    // In case if we request an entity with the search extension, multiple events are returned.
    // To identify the needed one, entityEventReference might be user
    EventReference? entityEventReference,
  }) async {
    final entitiesStream =
        requestEntities<T>(requestMessage, actionType: actionType, actionSource: actionSource);

    final entities = await entitiesStream.toList();
    return entities.isNotEmpty
        ? entityEventReference != null
            ? entities.reversed
                .firstWhereOrNull((entity) => entity.toEventReference() == entityEventReference)
            : entities.last
        : null;
  }

  Future<EventMessage> sign(
    EventSerializable entityData, {
    bool includeMasterPubkey = true,
  }) async {
    final mainWallet = await ref.read(mainWalletProvider.future);

    if (mainWallet == null) {
      throw MainWalletNotFoundException();
    }

    final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);

    if (eventSigner == null) {
      throw EventSignerNotFoundException();
    }

    return entityData.toEventMessage(
      eventSigner,
      tags: [
        if (includeMasterPubkey) MasterPubkeyTag(value: mainWallet.signingKey.publicKey).toTag(),
      ],
    );
  }

  Future<EventMessage> buildEventFromTagsAndSignWithMasterKey({
    required List<List<String>> tags,
    required int kind,
    required OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity,
  }) async {
    final currentIdentityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);

    if (currentIdentityKeyName == null) {
      throw const CurrentUserNotFoundException();
    }

    final mainWallet = await ref.read(mainWalletProvider.future);
    final ionIdentity = await ref.read(ionIdentityProvider.future);

    if (mainWallet == null) {
      throw MainWalletNotFoundException();
    }

    final createdAt = DateTime.now();
    final masterPubkey = mainWallet.signingKey.publicKey;

    final eventId = EventMessage.calculateEventId(
      publicKey: masterPubkey,
      createdAt: createdAt.microsecondsSinceEpoch,
      kind: kind,
      tags: tags,
      content: '',
    );

    final signResponse =
        await ionIdentity(username: currentIdentityKeyName).wallets.generateHashSignature(
              walletId: mainWallet.id,
              hash: eventId,
              onVerifyIdentity: onVerifyIdentity,
            );

    final curveName = switch (mainWallet.signingKey.curve) {
      'ed25519' => 'curve25519',
      _ => throw UnsupportedSignatureAlgorithmException(mainWallet.signingKey.curve)
    };

    final signaturePrefix = '${mainWallet.signingKey.scheme}/$curveName'.toLowerCase();
    final signatureBody =
        '${signResponse.signature['r']}${signResponse.signature['s']}'.replaceAll('0x', '');
    final signature = '$signaturePrefix:$signatureBody';

    return EventMessage(
      id: eventId,
      pubkey: masterPubkey,
      createdAt: createdAt.microsecondsSinceEpoch,
      kind: kind,
      tags: tags,
      content: '',
      sig: signature,
    );
  }

  void _handleWriteRelay(ActionSource actionSource, String writeRelayUrl) {
    if (actionSource is ActionSourceCurrentUser) {
      // Set current user write relay to get the correct firebase config
      ref.read(currentUserWriteRelayProvider.notifier).relay = writeRelayUrl;
    }
  }

  Future<List<EventMessage>> _buildMetadata({
    required List<EventMessage> events,
    required List<EventsMetadataBuilder> metadataBuilders,
  }) async {
    final parser = ref.read(eventParserProvider);
    final eventReferences =
        events.map((eventMessage) => parser.parse(eventMessage).toEventReference()).toList();
    final metadatas = await Future.wait(
      metadataBuilders.map((metadataBuilder) => metadataBuilder.buildMetadata(eventReferences)),
    );
    return Future.wait(metadatas.expand((metadata) => metadata).map(sign).toList());
  }

  Future<void> _sendEventsToRelay(
    List<EventMessage> events, {
    required IonConnectRelay relay,
  }) async {
    try {
      await relay.sendEvents(events).timeout(
            _defaultTimeout,
            onTimeout: () => throw TimeoutException(
              'Sending events ${events.map((event) => event.kind).toSet()} timed out after ${_defaultTimeout.inSeconds} seconds',
            ),
          );
    } catch (error) {
      // Ignore "relay-is-authoritative" errors as they are thrown by a
      // relay when the app sends an event with attached 21750 metadata to an
      // authoritative relay.
      //
      // That happens when the app sends an event to a relevant user relays
      // and those relays are shared with the current user. In this case the
      // error can be safely ignored as it basically means that the event
      // was already published to the relay.
      if (RelayAuthService.isRelayAuthoritativeError(error)) {
        return;
      } else {
        rethrow;
      }
    }
  }

  IonConnectEntity _parseAndCache(EventMessage event) {
    final parser = ref.read(eventParserProvider);
    final entity = parser.parse(event);
    if (entity is CacheableEntity) {
      ref.read(ionConnectCacheProvider.notifier).cache(entity);
    }
    return entity;
  }

  void _warnSendIssues(List<EventMessage> events) {
    final excludedKinds = [
      IonConnectGiftWrapEntity.kind,
      FileMetadataEntity.kind,
      UserDelegationEntity.kind,
      BadgeAwardEntity.kind,
      BadgeDefinitionEntity.kind,
      EventCountRequestEntity.kind,
    ];

    for (final event in events) {
      if (!excludedKinds.contains(event.kind) &&
          !event.tags.any((tag) => tag[0] == MasterPubkeyTag.tagName)) {
        Logger.error(
          EventMasterPubkeyNotFoundException(eventId: event.id),
          stackTrace: StackTrace.current,
        );
      }
    }
  }
}
