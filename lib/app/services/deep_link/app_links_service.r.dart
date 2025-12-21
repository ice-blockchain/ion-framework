// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/init_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/internal_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_links_service.r.g.dart';

@riverpod
Future<void> appReady(Ref ref) async {
  await ref.watch(initAppProvider.future);
  await ref.watch(splashReadyProvider.future);
}

@riverpod
Future<void> deepLinkHandler(Ref ref) async {
  void closeOpenModalsIfNeeded() {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    final router = GoRouter.maybeOf(context);
    final isMainModalOpen = router?.state.isMainModalOpen ?? false;

    if (isMainModalOpen || context.canPop()) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
  }

  void handlePath(String path) {
    closeOpenModalsIfNeeded();
    final currentContext = rootNavigatorKey.currentContext;
    if (currentContext != null && currentContext.mounted) {
      if (path == FeedRoute().location ||
          path == ChatRoute().location ||
          path == WalletRoute().location ||
          path == SelfProfileRoute().location) {
        GoRouter.of(currentContext).go(path);
      } else {
        GoRouter.of(currentContext).push(path);
      }
      ref.read(deeplinkPathProvider.notifier).clear();
    } else {
      // No navigator context yet; nothing to do.
    }
  }

  // Set up the listener FIRST to catch any state changes from initial link handling
  ref.listen<String?>(deeplinkPathProvider, (prev, next) {
    if (next != null) {
      handlePath(next);
    }
  });

  // Handle a path that may have been set before this listener was registered (cold start race)
  final pendingPath = ref.read(deeplinkPathProvider);
  if (pendingPath != null) {
    handlePath(pendingPath);
  }

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
          final uri = Uri.parse(initialLink);
          final location = internalDeepLinkService.getRouteLocation(uri.host, uri.pathSegments);
          if (location != null) {
            ref.read(deeplinkPathProvider.notifier).path = location;
          }
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
          final uri = Uri.parse(link);
          final location = internalDeepLinkService.getRouteLocation(uri.host, uri.pathSegments);
          if (location != null) {
            ref.read(deeplinkPathProvider.notifier).path = location;
          }
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
      Logger.log(
        'DeepLinkInitializer: AppsFlyer deeplink callback with path=$encodedEventReference, contentType=$contentType',
      );
      try {
        // Check if this is an internal deep link first
        final internalDeepLinkService = ref.read(internalDeepLinkServiceProvider);
        if (internalDeepLinkService.isInternalDeepLink(encodedEventReference)) {
          // For cold start (which is when this callback runs), use deeplinkPathProvider
          final uri = Uri.parse(encodedEventReference);
          final location = internalDeepLinkService.getRouteLocation(uri.host, uri.pathSegments);
          if (location != null) {
            ref.read(deeplinkPathProvider.notifier).path = location;
          }
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
            _ => null,
          };

          if (location != null) {
            ref.read(deeplinkPathProvider.notifier).path = location;
          }
        }
      } catch (error) {
        Logger.error('Deep link parsing error: $error');
      }
    },
  );
}

@riverpod
class DeeplinkPath extends _$DeeplinkPath {
  @override
  String? build() => null;

  set path(String path) => state = path;
  void clear() => state = null;
}
