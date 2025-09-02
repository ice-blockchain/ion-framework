// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_db_cache_notifier.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_service.r.g.dart';

@riverpod
Future<void> deepLinkHandler(Ref ref) async {
  // used only first time when app is opened from closed state (cold start)
  final appLinks = AppLinks();
  try {
    final initialLink = await appLinks.getInitialLinkString();

    if (initialLink != null) {
      final deepLinkService = ref.read(deepLinkServiceProvider);
      // need to wait for splash animation to complete before navigating
      final subscription = ref.listen(splashProvider, (prev, animationCompleted) {
        if (animationCompleted) {
          deepLinkService.resolveDeeplink(initialLink);
        }
      });
      ref.onDispose(subscription.close);
    }
  } catch (e) {
    Logger.error('Error getting initial link: $e');
  }

  // iOS handles warm start on AppDelegate level via AppsFlyer SDK
  if (Platform.isAndroid) {
    appLinks.stringLinkStream.listen(ref.read(deepLinkServiceProvider).resolveDeeplink);
  }

  // used when app is running in background (warm start)
  ref.listen<String?>(deeplinkPathProvider, (prev, next) {
    if (next != null) {
      final currentContext = rootNavigatorKey.currentContext;
      if (currentContext != null) {
        GoRouter.of(currentContext).push(next);
        ref.read(deeplinkPathProvider.notifier).clear();
      }
    }
  });
}

@riverpod
class DeeplinkPath extends _$DeeplinkPath {
  @override
  String? build() => null;

  set path(String path) => state = path;
  void clear() => state = null;
}

@Riverpod(keepAlive: true)
DeepLinkService deepLinkService(Ref ref) {
  final env = ref.read(envProvider.notifier);
  final templateId = env.get<String>(EnvVariable.AF_ONE_LINK_TEMPLATE_ID);
  final brandDomain = env.get<String>(EnvVariable.AF_BRAND_DOMAIN);
  final baseHost = env.get<String>(EnvVariable.AF_BASE_HOST);
  final shareAppName = env.get<String>(EnvVariable.SHARE_APP_NAME);
  return DeepLinkService(
    ref.watch(appsflyerSdkProvider),
    templateId: templateId,
    brandDomain: brandDomain,
    baseHost: baseHost,
    shareAppName: shareAppName,
  );
}

@riverpod
Future<void> deeplinkInitializer(Ref ref) async {
  final service = ref.read(deepLinkServiceProvider);

  Future<String?> handlePostDeepLink(
    EventReference eventReference,
    String encodedEventReference,
  ) async {
    final entity =
        await ref.read(ionConnectEntityWithCountersProvider(eventReference: eventReference).future);

    if (entity is ModifiablePostEntity) {
      if (entity.isStory) {
        return StoryViewerRoute(
          pubkey: entity.masterPubkey,
          initialStoryReference: encodedEventReference,
        ).location;
      }

      return PostDetailsRoute(eventReference: encodedEventReference).location;
    }

    return null;
  }

  bool isFallbackUrl(String encodedEventReference) {
    if (encodedEventReference == service._fallbackUrl) {
      return true;
    }
    final fallbackUri = Uri.parse(service._fallbackUrl);
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

    await ref.read(ionConnectDbCacheProvider.notifier).save(relaysEntity);
  }

  await service.init(
    onDeeplink: (encodedEventReference) async {
      try {
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
              await handlePostDeepLink(eventReference, encodedEventReference),
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
AppsflyerSdk appsflyerSdk(Ref ref) {
  final env = ref.watch(envProvider.notifier);
  final devKey = env.get<String>(EnvVariable.AF_DEV_KEY);
  final templateId = env.get<String>(EnvVariable.AF_ONE_LINK_TEMPLATE_ID);
  final appId = env.get<String>(EnvVariable.AF_APP_ID);

  return AppsflyerSdk(
    AppsFlyerOptions(
      afDevKey: devKey,
      appId: appId,
      appInviteOneLink: templateId,
      disableAdvertisingIdentifier: true,
      disableCollectASA: true,
      showDebug: kDebugMode,
      manualStart: true,
    ),
  );
}

final class DeepLinkService {
  DeepLinkService(
    this._appsflyerSdk, {
    required String templateId,
    required String brandDomain,
    required String baseHost,
    required String shareAppName,
  })  : _templateId = templateId,
        _brandDomain = brandDomain,
        _baseHost = baseHost,
        _shareAppName = shareAppName;

  final AppsflyerSdk _appsflyerSdk;

  final String _templateId;
  final String _brandDomain;
  final String _baseHost;
  final String _shareAppName;

  static final oneLinkUrlRegex = RegExp(
    r'@?(https://(ion\.onelink\.me|app\.online\.io|testnet\.app\.online\.io)/[A-Za-z0-9\-_/\?&%=#]*)',
  );

  // Defined on AppsFlyer portal for each template.
  // Used in case if generateInviteLink fails.
  String get _fallbackUrl => 'https://$_baseHost/$_templateId/feed';

  static const Duration _linkGenerationTimeout = Duration(seconds: 10);

  bool _isInitialized = false;

  Future<void> init({required void Function(String path) onDeeplink}) async {
    _appsflyerSdk
      ..onDeepLinking((link) {
        final path = link.deepLink?.deepLinkValue;
        if (path != null) {
          if (link.status == Status.FOUND) {
            if (path.isEmpty) return;

            return onDeeplink(path);
          }
        } else {
          final clickEvent = link.deepLink?.clickEvent;
          final host = clickEvent?['host'] as String?;
          if (host == _brandDomain) {
            final url = clickEvent?['link'] as String?;
            if (url != null) {
              _appsflyerSdk.resolveOneLinkUrl(url.replaceAll(_brandDomain, _baseHost));
              return;
            }
          }
        }
        onDeeplink(_fallbackUrl);
      })
      ..stop(true);

    final result = await _appsflyerSdk.initSdk(
      registerOnDeepLinkingCallback: true,
    );

    // For some reason AppsFlyer on Android and iOS returns different results...

    if (Platform.isAndroid && result is String) {
      _isInitialized = result == 'success';
      if (_isInitialized) {
        // Start the SDK for generating links and then stop reporting immediately
        // ios does not need this
        _appsflyerSdk
          ..startSDK()
          ..stop(true);
      }
    }

    if (Platform.isIOS && result is Map<dynamic, dynamic>) {
      _isInitialized = result['status'] == 'OK';
    }
  }

  /// Creates a deep link for the given path using AppsFlyer
  ///
  /// Returns the generated deep link URL, or a fallback URL if generation fails.
  /// The method has a timeout to prevent hanging indefinitely.
  ///
  /// [path] - The path to encode in the deep link
  /// [description] - The description to use for the deep link
  Future<String> createDeeplink({
    required String path,
    String? ogImageUrl,
    String? ogDescription,
  }) async {
    if (!_isInitialized) {
      Logger.log('AppsFlyer initialization failed');
      return _fallbackUrl;
    }

    final completer = Completer<String>();

    try {
      _appsflyerSdk.generateInviteLink(
        AppsFlyerInviteLinkParams(
          brandDomain: _brandDomain,
          customParams: {
            'deep_link_value': path,
            ...?_buildOgParams(
              ogImageUrl: ogImageUrl,
              ogDescription: ogDescription,
            ),
          },
        ),
        (dynamic data) => _handleInviteLinkSuccess(data, completer),
        (dynamic error) => _handleInviteLinkError(error, completer, 'SDK callback error'),
      );
    } catch (error) {
      _handleInviteLinkError(error, completer, 'SDK invocation error');
    }

    return completer.future.timeout(
      _linkGenerationTimeout,
      onTimeout: () {
        Logger.error('Deep link generation timed out after ${_linkGenerationTimeout.inSeconds}s');
        return _fallbackUrl;
      },
    );
  }

  Map<String, String>? _buildOgParams({
    String? ogImageUrl,
    String? ogDescription,
  }) {
    // Covers the case when deep link is being used for the reporting
    if (ogImageUrl == null && ogDescription == null) {
      return null;
    }

    // AppsFlyer requires a non-null or empty description because otherwise all og params will be not set at all
    final description = ogDescription.isEmpty ? ' ' : ogDescription!;
    final image = ogImageUrl.isEmpty ? ' ' : ogImageUrl!;

    return {
      'af_og_title': _shareAppName,
      'af_og_description': description,
      'af_og_image': image,
    };
  }

  void _handleInviteLinkSuccess(dynamic data, Completer<String> completer) {
    if (completer.isCompleted) return;

    try {
      final result = _parseResponseData(data);
      final link = result['userInviteURL'];

      if (link != null && link.isNotEmpty) {
        completer.complete(link);
      } else {
        Logger.error('Deep link generation failed: empty or null URL in response');
        completer.complete(_fallbackUrl);
      }
    } catch (error) {
      Logger.error('Deep link parsing error: $error');
      completer.complete(_fallbackUrl);
    }
  }

  void _handleInviteLinkError(dynamic error, Completer<String> completer, String context) {
    if (completer.isCompleted) {
      return;
    }

    Logger.error('AppsFlyer invite link generation error ($context), $error');
    completer.complete(_fallbackUrl);
  }

  Map<String, String?> _parseResponseData(dynamic data) {
    if (data == null) {
      throw ArgumentError('Response data is null');
    }

    final result = Map<dynamic, dynamic>.from(data as Map<dynamic, dynamic>);
    final payload = result['payload'];

    if (payload == null) {
      throw ArgumentError('Payload is missing from response');
    }

    return Map<String, String?>.from(payload as Map<String, dynamic>);
  }

  void resolveDeeplink(String url) => _appsflyerSdk.resolveOneLinkUrl(url);
}
