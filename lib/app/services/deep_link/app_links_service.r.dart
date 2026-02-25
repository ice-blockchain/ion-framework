// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/init_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/deep_link_mappers.dart';
import 'package:ion/app/services/deep_link/deep_link_navigate_event.dart';
import 'package:ion/app/services/deep_link/internal_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';
import 'package:ion/app/services/ion_connect/shareable_identifier.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_links_service.r.g.dart';

@riverpod
Future<void> appReady(Ref ref) async {
  await ref.watch(initAppProvider.future);
  await ref.watch(splashReadyProvider.future);
}

@riverpod
Future<void> deepLinkHandler(Ref ref) async {
  // used only first time when app is opened from closed state (cold start)
  final appLinks = AppLinks();
  String? handledInitialLink;

  Future<void> handleInitialLink() async {
    try {
      final initialLink = await appLinks.getInitialLinkString();

      if (initialLink != null) {
        handledInitialLink = initialLink;
        final appsflyerDeepLinkService = ref.read(appsflyerDeepLinkServiceProvider);
        final internalDeepLinkService = ref.read(internalDeepLinkServiceProvider);
        ref.read(splashProvider.notifier).animationCompleted = true;

        // If it's an internal link, handle it directly. Otherwise, let AppsFlyer resolve it.
        if (internalDeepLinkService.isInternalDeepLink(initialLink)) {
          _handleDeeplink(initialLink, ref);
        } else {
          appsflyerDeepLinkService.resolveDeeplink(initialLink);
        }
      }
    } catch (e) {
      Logger.error('Error getting initial link: $e');
    }
  }

  // Run initial link handling outside the provider build stack to avoid provider cycles.
  unawaited(Future.microtask(handleInitialLink));

  // iOS handles warm start on AppDelegate level via AppsFlyer SDK
  if (Platform.isAndroid) {
    appLinks.stringLinkStream.listen((link) {
      if (link != handledInitialLink) {
        final internalDeepLinkService = ref.read(internalDeepLinkServiceProvider);
        if (internalDeepLinkService.isInternalDeepLink(link)) {
          _handleDeeplink(link, ref);
        } else {
          ref.read(appsflyerDeepLinkServiceProvider).resolveDeeplink(link);
        }
      }
    });
  }
}

@riverpod
Future<void> deeplinkInitializer(Ref ref) async {
  final service = ref.read(appsflyerDeepLinkServiceProvider);
  final internalDeepLinkService = ref.read(internalDeepLinkServiceProvider);
  String? lastDeeplink;
  DateTime? lastDeeplinkTimestamp;

  // AppsFlyer have a bug: sometimes sends duplicate deeplinks in a short time frame, so we filter them out
  bool shouldIgnoreDuplicate(String deeplink) {
    final now = DateTime.now();
    final isDuplicate = lastDeeplink == deeplink &&
        lastDeeplinkTimestamp != null &&
        now.difference(lastDeeplinkTimestamp!) < const Duration(seconds: 1);
    lastDeeplink = deeplink;
    lastDeeplinkTimestamp = now;
    return isDuplicate;
  }

  await service.init(
    internalDeepLinkService: internalDeepLinkService,
    onDeeplink: (encodedEventReference, contentType) async {
      if (shouldIgnoreDuplicate(encodedEventReference)) {
        Logger.log(
          'DeepLinkInitializer: duplicate AppsFlyer deeplink ignored for path=$encodedEventReference, contentType=$contentType',
        );
        return;
      }

      Logger.log(
        'DeepLinkInitializer: AppsFlyer deeplink callback with path=$encodedEventReference, contentType=$contentType',
      );

      if (internalDeepLinkService.isInternalDeepLink(encodedEventReference)) {
        _handleDeeplink(encodedEventReference, ref);
        return;
      }

      if (_isFallbackUrl(encodedEventReference, service.fallbackUrl)) {
        return;
      }

      try {
        final shareableIdentifier = _decodeShareableIdentifier(ref, encodedEventReference);
        final eventReference = EventReference.fromShareableIdentifier(shareableIdentifier);

        await _cacheRelays(
          ref,
          shareableIdentifier.relays,
          eventReference.masterPubkey,
        );

        final location = await _resolveDeepLinkRoute(
          ref: ref,
          eventReference: eventReference,
          encodedRef: encodedEventReference,
          contentType: contentType,
        );

        if (location != null) {
          ref.read(uiEventQueueNotifierProvider.notifier).emit(DeeplinkNavigateEvent(location));
        }
      } catch (error) {
        Logger.error('Deep link parsing error: $error');
      }
    },
  );
}

bool _isFallbackUrl(String encodedRef, String fallbackUrl) {
  if (encodedRef == fallbackUrl) return true;

  final fallbackUri = Uri.parse(fallbackUrl);
  if (fallbackUri.pathSegments.isNotEmpty) {
    return '/${fallbackUri.pathSegments.last}' == encodedRef;
  }
  return false;
}

ShareableIdentifier _decodeShareableIdentifier(Ref ref, String encodedRef) {
  final encodedShareableIdentifier = IonConnectUriProtocolService().decode(encodedRef);

  if (encodedShareableIdentifier == null) {
    throw ShareableIdentifierDecodeException(encodedRef);
  }

  return ref
      .read(ionConnectUriIdentifierServiceProvider)
      .decodeShareableIdentifiers(payload: encodedShareableIdentifier);
}

Future<void> _cacheRelays(
  Ref ref,
  List<String> encodedRelays,
  String pubkey,
) async {
  if (encodedRelays.isEmpty) return;

  final relaysData = UserRelaysData(
    list: encodedRelays
        .map(
          (encodedRelay) => UserRelay.fromTag(
            List<String>.from(jsonDecode(encodedRelay) as List<dynamic>),
          ),
        )
        .toList(),
  );

  final relaysEntity = UserRelaysEntity(
    id: '',
    pubkey: pubkey,
    masterPubkey: pubkey,
    signature: '',
    createdAt: DateTime.now().microsecondsSinceEpoch,
    data: relaysData,
  );

  await ref.read(ionConnectDatabaseCacheProvider.notifier).saveEntity(relaysEntity);
}

Future<String?> _resolveDeepLinkRoute({
  required Ref ref,
  required EventReference eventReference,
  required String encodedRef,
  required SharedContentType? contentType,
}) async {
  final entity = await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
  if (entity == null) return null;

  if (entity is CommunityTokenActionEntity) {
    return PostDetailsRoute(eventReference: encodedRef).location;
  }

  if (eventReference is ReplaceableEventReference) {
    switch (eventReference.kind) {
      case ModifiablePostEntity.kind:
        return _handlePostEntity(entity, encodedRef, contentType);
      case ArticleEntity.kind:
        return ArticleDetailsRoute(eventReference: encodedRef).location;
      case UserMetadataEntity.kind:
        return ProfileRoute(pubkey: eventReference.masterPubkey).location;
      case CommunityTokenDefinitionEntity.kind:
        return _handleCommunityTokenEntity(ref, entity);
      default:
        return null;
    }
  }

  return null;
}

Future<String?> _handlePostEntity(
  IonConnectEntity? entity,
  String encodedRef,
  SharedContentType? contentType,
) async {
  if (entity is! ModifiablePostEntity) return null;

  final effectiveContentType = contentType ?? mapEntityToSharedContentType(entity);

  if (effectiveContentType == SharedContentType.story || entity.isStory) {
    return StoryViewerRoute(
      pubkey: entity.masterPubkey,
      initialStoryReference: encodedRef,
    ).location;
  }

  if (effectiveContentType == SharedContentType.postWithVideo) {
    return FullscreenMediaRoute(
      eventReference: encodedRef,
      initialMediaIndex: 0,
    ).location;
  }

  return PostDetailsRoute(eventReference: encodedRef).location;
}

Future<String?> _handleCommunityTokenEntity(
  Ref ref,
  IonConnectEntity? entity,
) async {
  if (entity is CommunityTokenDefinitionEntity) {
    return TokenizedCommunityRoute(
      externalAddress: entity.data.externalAddress,
    ).location;
  }
  return null;
}

void _handleDeeplink(
  String link,
  Ref ref,
) {
  final uri = Uri.parse(link);
  final internalDeepLinkService = ref.read(internalDeepLinkServiceProvider);
  final location = internalDeepLinkService.getRouteLocation(uri.host, uri.pathSegments);
  if (location != null) {
    ref.read(uiEventQueueNotifierProvider.notifier).emit(
          DeeplinkNavigateEvent(location),
        );
  }
}
