// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_service.r.g.dart';

@riverpod
void deepLinkHandler(Ref ref) {
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
  return DeepLinkService(
    ref.watch(appsflyerSdkProvider),
    templateId: templateId,
    brandDomain: brandDomain,
    baseHost: baseHost,
  );
}

@riverpod
Future<void> deeplinkInitializer(Ref ref) async {
  final service = ref.read(deepLinkServiceProvider);

  Future<String?> handlePostDeepLink(
    EventReference event,
    String eventReference,
  ) async {
    final entity = await ref.read(ionConnectEntityProvider(eventReference: event).future);

    if (entity is ModifiablePostEntity) {
      if (entity.isStory) {
        return StoryViewerRoute(
          pubkey: entity.masterPubkey,
          initialStoryReference: eventReference,
        ).location;
      }

      return PostDetailsRoute(eventReference: eventReference).location;
    }

    return null;
  }

  bool isFallbackUrl(String eventReference) {
    final fallbackUri = Uri.parse(service._fallbackUrl);
    final segments = fallbackUri.pathSegments;
    if (segments.isNotEmpty) {
      final lastSegment = segments.last;
      return '/$lastSegment' == eventReference;
    }

    return false;
  }

  await service.init(
    onDeeplink: (eventReference) async {
      try {
        if (isFallbackUrl(eventReference)) {
          // Just open the app in case of fallback url
          return;
        }

        final event = EventReference.fromEncoded(eventReference);

        if (event is ReplaceableEventReference) {
          final location = switch (event.kind) {
            ModifiablePostEntity.kind => await handlePostDeepLink(event, eventReference),
            ArticleEntity.kind => ArticleDetailsRoute(eventReference: eventReference).location,
            UserMetadataEntity.kind => ProfileRoute(pubkey: event.masterPubkey).location,
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
  })  : _templateId = templateId,
        _brandDomain = brandDomain,
        _baseHost = baseHost;

  final AppsflyerSdk _appsflyerSdk;

  final String _templateId;
  final String _brandDomain;
  final String _baseHost;

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
  Future<String> createDeeplink(String path) async {
    if (!_isInitialized) {
      Logger.log('AppsFlyer initialization failed');
      return _fallbackUrl;
    }

    final completer = Completer<String>();

    try {
      _appsflyerSdk.generateInviteLink(
        AppsFlyerInviteLinkParams(
          brandDomain: _brandDomain,
          customParams: {'deep_link_value': path},
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
