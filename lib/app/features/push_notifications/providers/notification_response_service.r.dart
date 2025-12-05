// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/push_notifications/data/models/ion_connect_push_data_payload.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_response_service.r.g.dart';

class NotificationResponseService {
  NotificationResponseService({
    required Future<GiftUnwrapService> Function() getGiftUnwrapService,
    required UserMetadataEntity? Function(String pubkey) getUserMetadata,
    required Future<IonConnectEntity?> Function(EventReference eventReference) getEntityData,
    required EventParser eventParser,
    required String? currentPubkey,
    required Future<AuthState> Function() getAuthState,
    required Future<void> Function(String identityKeyName) setCurrentUser,
    required void Function() markShowNotificationAfterSwitchingAcc,
    required Future<String?> Function(String identityKeyName) userPubkeyByIdentityKeyName,
  })  : _getGiftUnwrapService = getGiftUnwrapService,
        _getUserMetadata = getUserMetadata,
        _getEntityData = getEntityData,
        _eventParser = eventParser,
        _currentPubkey = currentPubkey,
        _getAuthState = getAuthState,
        _setCurrentUser = setCurrentUser,
        _markShowNotificationAfterSwitchingAcc = markShowNotificationAfterSwitchingAcc,
        _userPubkeyByIdentityKeyName = userPubkeyByIdentityKeyName;

  final Future<GiftUnwrapService> Function() _getGiftUnwrapService;
  final UserMetadataEntity? Function(String pubkey) _getUserMetadata;
  final Future<IonConnectEntity?> Function(EventReference eventReference) _getEntityData;
  final EventParser _eventParser;
  final String? _currentPubkey;
  final Future<AuthState> Function() _getAuthState;
  final Future<void> Function(String identityKeyName) _setCurrentUser;
  final void Function() _markShowNotificationAfterSwitchingAcc;
  final Future<String?> Function(String identityKeyName) _userPubkeyByIdentityKeyName;

  /// Checks if any modal is open and closes it before navigation
  void _checkModal() {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      final router = GoRouter.maybeOf(context);
      final isMainModalOpen = router?.state.isMainModalOpen ?? false;

      if (isMainModalOpen || context.canPop()) {
        // there's no animation for popUntil, so no need to delay
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      }
    }
  }

  void _closeAllModalsAndNavigateToHomeFeed() {
    final context = _getNavigatorContext();
    if (context != null) {
      if (context.canPop()) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      }
      FeedRoute().go(context);
    }
  }

  /// Safely gets the navigator context, returning null if context is null or not mounted
  BuildContext? _getNavigatorContext() {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      return context;
    }
    return null;
  }

  RouteMatchList get _currentRouteMatchList {
    final router = GoRouter.of(rootNavigatorKey.currentContext!);
    final lastMatch = router.routerDelegate.currentConfiguration.last;
    return lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : router.routerDelegate.currentConfiguration;
  }

  Future<void> handleNotificationResponse(
    Map<String, dynamic> response, {
    required bool isInitialNotification,
  }) async {
    try {
      final notificationPayload = await IonConnectPushDataPayload.fromEncoded(
        response,
        unwrapGift: (eventMassage) async {
          final giftUnwrapService = await _getGiftUnwrapService();

          final event = await giftUnwrapService.unwrap(eventMassage);
          final userMetadata = _getUserMetadata(event.masterPubkey);

          return (event, userMetadata);
        },
      );

      final entity = _eventParser.parse(notificationPayload.event);

      await _switchToRecipientUserForEntity(notificationPayload);

      _checkModal();

      switch (entity) {
        case ModifiablePostEntity():
        case PostEntity():
          await _openPostDetail(
            entity.toEventReference(),
            isInitialNotification: isInitialNotification,
          );
        case GenericRepostEntity() when entity.data.kind == ArticleEntity.kind:
          await _openArticleDetail(
            entity.data.eventReference,
            isInitialNotification: isInitialNotification,
          );
        case GenericRepostEntity() when entity.data.kind == ModifiablePostEntity.kind:
          await _openPostDetail(
            entity.data.eventReference,
            isInitialNotification: isInitialNotification,
          );
        case RepostEntity():
          await _openPostDetail(
            entity.data.eventReference,
            isInitialNotification: isInitialNotification,
          );
        case ReactionEntity():
          final eventReference = entity.data.eventReference;
          final entityData = await _getEntityData(eventReference);
          // Check if the referenced entity is a story
          if (entityData is ModifiablePostEntity && entityData.isStory) {
            await _openStoryViewer(
              entityData.masterPubkey,
              eventReference,
              isInitialNotification: isInitialNotification,
            );
          } else {
            await _openPostDetail(
              eventReference,
              isInitialNotification: isInitialNotification,
            );
          }
        case FollowListEntity():
          await _openProfileDetail(
            entity.masterPubkey,
            isInitialNotification: isInitialNotification,
          );
        case IonConnectGiftWrapEntity():
          await _handleGiftWrap(
            notificationPayload.event,
            isInitialNotification: isInitialNotification,
          );
        default:
          throw UnsupportedEntityType(entity);
      }
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: 'Error handling notification response');
    }
  }

  String? _getRecipientPubkey(IonConnectEntity entity) {
    return switch (entity) {
      ReactionEntity() => entity.data.eventReference.masterPubkey,
      RepostEntity() => entity.data.eventReference.masterPubkey,
      GenericRepostEntity() => entity.data.eventReference.masterPubkey,
      ModifiablePostEntity() => () {
          final relatedPubkeys = entity.data.relatedPubkeys;
          if (relatedPubkeys != null && relatedPubkeys.isNotEmpty) {
            return relatedPubkeys.first.value;
          }
          final quotedEvent = entity.data.quotedEvent;
          return quotedEvent?.eventReference.masterPubkey;
        }(),
      PostEntity() => () {
          final relatedPubkeys = entity.data.relatedPubkeys;
          if (relatedPubkeys != null && relatedPubkeys.isNotEmpty) {
            return relatedPubkeys.first.value;
          }
          final quotedEvent = entity.data.quotedEvent;
          return quotedEvent?.eventReference.masterPubkey;
        }(),
      FollowListEntity() => entity.masterPubkeys.lastOrNull,
      IonConnectGiftWrapEntity() => () {
          final relatedPubkeys = entity.data.relatedPubkeys;
          if (relatedPubkeys.isNotEmpty) {
            return relatedPubkeys.first.value;
          }
          return null;
        }(),
      _ => null,
    };
  }

  Future<void> _switchToRecipientUserForEntity(
    IonConnectPushDataPayload notificationPayload,
  ) async {
    if (_currentPubkey != null && notificationPayload.isRecipient(_currentPubkey)) {
      return;
    }

    _closeAllModalsAndNavigateToHomeFeed();

    final entity = _eventParser.parse(notificationPayload.event);
    final recipientPubkey = _getRecipientPubkey(entity);
    if (recipientPubkey == null) {
      return;
    }

    final authState = await _getAuthState();
    final authenticatedIdentityKeyNames = authState.authenticatedIdentityKeyNames;

    String? recipientIdentityKeyName;

    final pubkeyResults = await Future.wait(
      authenticatedIdentityKeyNames.map(_userPubkeyByIdentityKeyName),
    );

    for (final entry in authenticatedIdentityKeyNames.asMap().entries) {
      if (pubkeyResults[entry.key] == recipientPubkey) {
        recipientIdentityKeyName = entry.value;
        break;
      }
    }

    if (recipientIdentityKeyName != null) {
      _markShowNotificationAfterSwitchingAcc();
      await _setCurrentUser(recipientIdentityKeyName);
      await _getAuthState();
    }
  }

  Future<void> _handleGiftWrap(EventMessage giftWrap, {bool isInitialNotification = false}) async {
    final giftUnwrapService = await _getGiftUnwrapService();

    if (_currentPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final rumor = await giftUnwrapService.unwrap(giftWrap);

    switch (rumor.kind) {
      case ReplaceablePrivateDirectMessageEntity.kind:
      case PrivateMessageReactionEntity.kind:
      case FundsRequestEntity.kind:
      case WalletAssetEntity.kind:
        await _openChat(rumor.masterPubkey, isInitialNotification: isInitialNotification);
      default:
        throw UnsupportedEntityType(rumor);
    }
  }

  Future<void> _openPostDetail(
    EventReference eventReference, {
    bool isInitialNotification = false,
  }) async {
    final context = _getNavigatorContext();
    if (context == null) {
      return;
    }

    final route = PostDetailsRoute(eventReference: eventReference.encode());
    // Get path without query parameters
    final routePath = route.location.split(IonConnectUriProtocolService.prefix).first;
    final currentPath = _currentRouteMatchList.fullPath.split(':').first;

    if (isInitialNotification) {
      route.pushReplacement(context);
      return;
    }

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();

      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(context);
      return;
    }

    await route.push<void>(context);
  }

  Future<void> _openArticleDetail(
    EventReference eventReference, {
    bool isInitialNotification = false,
  }) async {
    final context = _getNavigatorContext();
    if (context == null) {
      return;
    }

    final route = ArticleDetailsRoute(eventReference: eventReference.encode());
    // Get path without query parameters
    final routePath = route.location.split(IonConnectUriProtocolService.prefix).first;
    final currentPath = _currentRouteMatchList.fullPath.split(':').first;

    if (isInitialNotification) {
      route.pushReplacement(context);
      return;
    }

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();
      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(context);
      return;
    }

    await route.push<void>(context);
  }

  Future<void> _openProfileDetail(String pubkey, {bool isInitialNotification = false}) async {
    final context = _getNavigatorContext();
    if (context == null) {
      return;
    }

    final route = ProfileRoute(pubkey: pubkey);
    final routePath = route.location.split('?').first;
    final currentPath = _currentRouteMatchList.fullPath;

    if (isInitialNotification) {
      route.pushReplacement(context);
      return;
    }

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();
      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(context);
      return;
    }

    await route.push<void>(context);
  }

  Future<void> _openChat(String pubkey, {bool isInitialNotification = false}) async {
    final context = _getNavigatorContext();
    if (context == null) {
      return;
    }

    final route = ConversationRoute(receiverMasterPubkey: pubkey);
    final routePath = route.location.split('?').first;
    final currentPath = _currentRouteMatchList.fullPath;

    if (isInitialNotification) {
      route.pushReplacement(context);
      return;
    }

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();
      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(context);
      return;
    }

    await route.push<void>(context);
  }

  Future<void> _openStoryViewer(
    String pubkey,
    EventReference eventReference, {
    bool isInitialNotification = false,
  }) async {
    final context = _getNavigatorContext();
    if (context == null) {
      return;
    }

    final route = StoryViewerRoute(
      pubkey: pubkey,
      initialStoryReference: eventReference.encode(),
    );
    // Get path without query parameters
    final routePath = route.location.split(IonConnectUriProtocolService.prefix).first;
    final currentPath = _currentRouteMatchList.fullPath.split(':').first;

    if (isInitialNotification) {
      route.pushReplacement(context);
      return;
    }

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();

      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(context);
      return;
    }

    await route.push<void>(context);
  }
}

@riverpod
NotificationResponseService notificationResponseService(Ref ref) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  Future<GiftUnwrapService> getGiftUnwrapService() => ref.watch(giftUnwrapServiceProvider.future);
  UserMetadataEntity? getUserMetadata(String pubkey) =>
      ref.watch(userMetadataProvider(pubkey)).valueOrNull;
  Future<IonConnectEntity?> getEntityData(EventReference eventReference) =>
      ref.read(ionConnectEntityWithCountersProvider(eventReference: eventReference).future);
  final eventParser = ref.watch(eventParserProvider);
  Future<AuthState> getAuthState() => ref.read(authProvider.future);
  Future<void> setCurrentUser(String identityKeyName) =>
      ref.read(authProvider.notifier).setCurrentUser(identityKeyName);
  void markShowNotificationAfterSwitchingAcc() {
    ref.read(userSwitchInProgressProvider.notifier).needToShowPushSwitchNotification();
  }

  Future<String?> userPubkeyByIdentityKeyName(String identityKeyName) =>
      ref.read(userPubkeyByIdentityKeyNameProvider(identityKeyName).future);

  return NotificationResponseService(
    getGiftUnwrapService: getGiftUnwrapService,
    getUserMetadata: getUserMetadata,
    getEntityData: getEntityData,
    eventParser: eventParser,
    currentPubkey: currentPubkey,
    getAuthState: getAuthState,
    setCurrentUser: setCurrentUser,
    markShowNotificationAfterSwitchingAcc: markShowNotificationAfterSwitchingAcc,
    userPubkeyByIdentityKeyName: userPubkeyByIdentityKeyName,
  );
}
