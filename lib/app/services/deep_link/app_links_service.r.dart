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
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/deep_link_navigate_event.dart';
import 'package:ion/app/services/deep_link/internal_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';
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
  String? lastDeeplink;
  DateTime? lastDeeplinkTimestamp;

  // AppsFlyer have a bug
  // Sometimes sends duplicate deeplinks in a short time frame, so we filter them out
  bool shouldIgnoreDuplicate(String deeplink) {
    final now = DateTime.now();
    final isDuplicate = lastDeeplink == deeplink &&
        lastDeeplinkTimestamp != null &&
        now.difference(lastDeeplinkTimestamp!) < const Duration(seconds: 1);
    lastDeeplink = deeplink;
    lastDeeplinkTimestamp = now;

    return isDuplicate;
  }

  Future<String?> handlePostDeepLink(
    EventReference eventReference,
    String encodedEventReference,
    SharedContentType? contentType,
  ) async {
    final entity = await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);

    if (entity is ModifiablePostEntity) {
      final effectiveContentType = contentType ?? mapEntityToSharedContentType(entity);

      if (effectiveContentType == SharedContentType.story || entity.isStory) {
        return StoryViewerRoute(
          pubkey: entity.masterPubkey,
          initialStoryReference: encodedEventReference,
        ).location;
      }

      if (effectiveContentType == SharedContentType.postWithVideo) {
        return FullscreenMediaRoute(
          eventReference: encodedEventReference,
          initialMediaIndex: 0,
        ).location;
      }

      return PostDetailsRoute(eventReference: encodedEventReference).location;
    }

    return null;
  }

  Future<String?> handleCommunityTokenDeepLink(
    EventReference eventReference,
    String encodedEventReference,
  ) async {
    final entity = await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
    if (entity is CommunityTokenDefinitionEntity) {
      final data = TokenizedCommunityRoute(externalAddress: entity.data.externalAddress).location;
      return data;
    }
    return null;
  }

  bool isFallbackUrl(String encodedEventReference) {
    if (encodedEventReference == service.fallbackUrl) {
      return true;
    }
    final fallbackUri = Uri.parse(service.fallbackUrl);
    final segments = fallbackUri.pathSegments;
    if (segments.isNotEmpty) {
      final lastSegment = segments.last;

      return '/$lastSegment' == encodedEventReference;
    }

    return false;
  }

  Future<void> cacheRelays(List<String> encodedRelays, {required String pubkey}) async {
    if (encodedRelays.isEmpty) return;

    final relaysData = UserRelaysData(
      list: [
        for (final encodedRelay in encodedRelays)
          UserRelay.fromTag(
            List<String>.from(jsonDecode(encodedRelay) as List<dynamic>),
          ),
      ],
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

  await service.init(
    internalDeepLinkService: ref.read(internalDeepLinkServiceProvider),
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
      try {
        // Check if this is an internal deep link first
        final internalDeepLinkService = ref.read(internalDeepLinkServiceProvider);
        if (internalDeepLinkService.isInternalDeepLink(encodedEventReference)) {
          _handleDeeplink(encodedEventReference, ref);
          return;
        }

        if (isFallbackUrl(encodedEventReference)) {
          // Just open the app in case of fallback url
          return;
        }

        final encodedShareableIdentifier =
            IonConnectUriProtocolService().decode(encodedEventReference);

        if (encodedShareableIdentifier == null) {
          throw ShareableIdentifierDecodeException(encodedEventReference);
        }

        final shareableIdentifier = ref
            .read(ionConnectUriIdentifierServiceProvider)
            .decodeShareableIdentifiers(payload: encodedShareableIdentifier);

        final eventReference = EventReference.fromShareableIdentifier(shareableIdentifier);

        await cacheRelays(shareableIdentifier.relays, pubkey: eventReference.masterPubkey);

        if (eventReference is ReplaceableEventReference) {
          final location = switch (eventReference.kind) {
            ModifiablePostEntity.kind =>
              await handlePostDeepLink(eventReference, encodedEventReference, contentType),
            ArticleEntity.kind =>
              ArticleDetailsRoute(eventReference: encodedEventReference).location,
            UserMetadataEntity.kind => ProfileRoute(pubkey: eventReference.masterPubkey).location,
            CommunityTokenDefinitionEntity.kind =>
              await handleCommunityTokenDeepLink(eventReference, encodedEventReference),
            _ => null,
          };

          if (location != null) {
            ref.read(uiEventQueueNotifierProvider.notifier).emit(
                  DeeplinkNavigateEvent(location),
                );
          }
        }
      } catch (error) {
        Logger.error('Deep link parsing error: $error');
      }
    },
  );
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
