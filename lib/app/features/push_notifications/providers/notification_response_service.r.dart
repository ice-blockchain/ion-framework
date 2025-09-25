// SPDX-License-Identifier: ice License 1.0

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/gift_unwrap_service_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
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
    required EventParser eventParser,
    required String? currentPubkey,
  })  : _getGiftUnwrapService = getGiftUnwrapService,
        _getUserMetadata = getUserMetadata,
        _eventParser = eventParser,
        _currentPubkey = currentPubkey;

  final Future<GiftUnwrapService> Function() _getGiftUnwrapService;
  final UserMetadataEntity? Function(String pubkey) _getUserMetadata;
  final EventParser _eventParser;
  final String? _currentPubkey;

  /// Checks if any modal is open and closes it before navigation
  Future<void> _checkModal() async {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      final router = GoRouter.maybeOf(context);
      final isMainModalOpen = router?.state.isMainModalOpen ?? false;
      final canPop = context.canPop();

      if (isMainModalOpen || canPop) {
        context.pop();
        // Wait for modal to close
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  RouteMatchList get _currentRouteMatchList {
    final router = GoRouter.of(rootNavigatorKey.currentContext!);
    final lastMatch = router.routerDelegate.currentConfiguration.last;
    return lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : router.routerDelegate.currentConfiguration;
  }

  Future<void> handleNotificationResponse(Map<String, dynamic> response) async {
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

      await _checkModal();

      switch (entity) {
        case ModifiablePostEntity():
        case PostEntity():
          await _openPostDetail(entity.toEventReference());
        case GenericRepostEntity() when entity.data.kind == ArticleEntity.kind:
          await _openArticleDetail(entity.data.eventReference);
        case GenericRepostEntity() when entity.data.kind == ModifiablePostEntity.kind:
          await _openPostDetail(entity.data.eventReference);
        case RepostEntity():
          await _openPostDetail(entity.data.eventReference);
        case ReactionEntity():
          await _openPostDetail(entity.data.eventReference);
        case FollowListEntity():
          await _openProfileDetail(entity.masterPubkey);
        case IonConnectGiftWrapEntity():
          await _handleGiftWrap(notificationPayload.event);
        default:
          throw UnsupportedEntityType(entity);
      }
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: 'Error handling notification response');
    }
  }

  Future<void> _handleGiftWrap(EventMessage giftWrap) async {
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
        await _openChat(rumor.masterPubkey);
      default:
        throw UnsupportedEntityType(rumor);
    }
  }

  Future<void> _openPostDetail(EventReference eventReference) async {
    final route = PostDetailsRoute(eventReference: eventReference.encode());
    // Get path without query parameters
    final routePath = route.location.split(IonConnectUriProtocolService.prefix).first;
    final currentPath = _currentRouteMatchList.fullPath.split(':').first;

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();
      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(rootNavigatorKey.currentContext!);
      return;
    }

    await route.push<void>(rootNavigatorKey.currentContext!);
  }

  Future<void> _openArticleDetail(EventReference eventReference) async {
    final route = ArticleDetailsRoute(eventReference: eventReference.encode());
    // Get path without query parameters
    final routePath = route.location.split(IonConnectUriProtocolService.prefix).first;
    final currentPath = _currentRouteMatchList.fullPath.split(':').first;

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();
      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(rootNavigatorKey.currentContext!);
      return;
    }

    await route.push<void>(rootNavigatorKey.currentContext!);
  }

  Future<void> _openProfileDetail(String pubkey) async {
    final route = ProfileRoute(pubkey: pubkey);
    final routePath = route.location.split('?').first;
    final currentPath = _currentRouteMatchList.fullPath;

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();
      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(rootNavigatorKey.currentContext!);
      return;
    }

    await route.push<void>(rootNavigatorKey.currentContext!);
  }

  Future<void> _openChat(String pubkey) async {
    final route = ConversationRoute(receiverMasterPubkey: pubkey);
    final routePath = route.location.split('?').first;
    final currentPath = _currentRouteMatchList.fullPath;

    if (routePath == currentPath) {
      final currentLocation = _currentRouteMatchList.uri.toString();
      if (route.location == currentLocation) {
        return;
      }

      route.pushReplacement(rootNavigatorKey.currentContext!);
      return;
    }

    await route.push<void>(rootNavigatorKey.currentContext!);
  }
}

@riverpod
NotificationResponseService notificationResponseService(Ref ref) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  Future<GiftUnwrapService> getGiftUnwrapService() => ref.watch(giftUnwrapServiceProvider.future);
  UserMetadataEntity? getUserMetadata(String pubkey) =>
      ref.read(userMetadataFromDbProvider(pubkey));
  final eventParser = ref.watch(eventParserProvider);

  return NotificationResponseService(
    getGiftUnwrapService: getGiftUnwrapService,
    getUserMetadata: getUserMetadata,
    eventParser: eventParser,
    currentPubkey: currentPubkey,
  );
}
