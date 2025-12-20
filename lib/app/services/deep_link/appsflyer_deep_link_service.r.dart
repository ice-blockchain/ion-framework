// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/deep_link/internal_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appsflyer_deep_link_service.r.g.dart';

const _contentTypeKey = 'content_type';

/// Maps an IonConnectEntity to its corresponding SharedContentType
/// based on entity properties like isStory and hasVideo
///
/// Priority order:
/// 1. Stories (regardless of media type) -> story
/// 2. Regular posts with video -> postWithVideo
/// 3. Regular posts -> post
/// 4. Articles -> article
/// 5. User profiles -> profile
SharedContentType mapEntityToSharedContentType(IonConnectEntity entity) {
  return switch (entity) {
    ModifiablePostEntity() when entity.isStory => SharedContentType.story,
    ModifiablePostEntity() when entity.data.hasVideo => SharedContentType.postWithVideo,
    ModifiablePostEntity() => SharedContentType.post,
    ArticleEntity() => SharedContentType.article,
    UserMetadataEntity() => SharedContentType.profile,
    _ => throw UnsupportedError('Unsupported IonConnectEntity: $entity'),
  };
}

@Riverpod(keepAlive: true)
AppsFlyerDeepLinkService appsflyerDeepLinkService(Ref ref) {
  final env = ref.read(envProvider.notifier);
  final devKey = env.get<String>(EnvVariable.AF_DEV_KEY);
  final appId = env.get<String>(EnvVariable.AF_APP_ID);
  final templateId = env.get<String>(EnvVariable.AF_ONE_LINK_TEMPLATE_ID);
  final brandDomain = env.get<String>(EnvVariable.AF_BRAND_DOMAIN);
  final baseHost = env.get<String>(EnvVariable.AF_BASE_HOST);

  final sdk = AppsflyerSdk(
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

  return AppsFlyerDeepLinkService(
    sdk,
    templateId: templateId,
    brandDomain: brandDomain,
    baseHost: baseHost,
  );
}

final class AppsFlyerDeepLinkService {
  AppsFlyerDeepLinkService(
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
  String get fallbackUrl => 'https://$_baseHost/$_templateId/feed';

  static const Duration _linkGenerationTimeout = Duration(seconds: 10);

  bool _isInitialized = false;

  Future<void> init({
    required void Function(String path, SharedContentType? contentType) onDeeplink,
    required InternalDeepLinkService internalDeepLinkService,
  }) async {
    await _appsflyerSdk.setAppInviteOneLinkID(_templateId, (dynamic data) {
      Logger.log('AppsFlyer setAppInviteOneLinkIDCallback callback: $data');
    });
    _appsflyerSdk
      ..onDeepLinking((link) {
        final path = link.deepLink?.deepLinkValue;
        final contentType = _extractContentTypeFromLink(link);

        if (path != null) {
          if (link.status == Status.FOUND) {
            if (path.isEmpty) return;

            return onDeeplink(path, contentType);
          }
        } else {
          final clickEvent = link.deepLink?.clickEvent;

          // Check if this is an internal deep link (uses env scheme)
          final rawLink = clickEvent?['link'] as String?;
          if (rawLink != null) {
            if (internalDeepLinkService.isInternalDeepLink(rawLink)) {
              // This is an internal deep link, pass it through
              return onDeeplink(rawLink, null);
            }
          }

          final host = clickEvent?['host'] as String?;
          if (host == _brandDomain) {
            final url = clickEvent?['link'] as String?;
            if (url != null) {
              _appsflyerSdk.resolveOneLinkUrl(url.replaceAll(_brandDomain, _baseHost));
              return;
            }
          }
        }
        onDeeplink(fallbackUrl, null);
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
  /// The method has a timeout to prevent hanging indefinitely and retry logic
  /// to handle cases where AppsFlyer returns invalid URLs.
  ///
  /// [path] - The path to encode in the deep link
  /// [contentType] - The type of content being shared (required)
  /// [ogTitle] - The title to use for the deep link
  /// [ogImageUrl] - The image URL to use for the deep link
  /// [ogDescription] - The description to use for the deep link
  Future<String> createDeeplink({
    required String path,
    SharedContentType? contentType,
    String? ogTitle,
    String? ogImageUrl,
    String? ogDescription,
  }) async {
    if (!_isInitialized) {
      Logger.log('AppsFlyer initialization failed');
      return fallbackUrl;
    }

    try {
      return await withRetry(
        ({error}) async {
          final result = await _generateInviteLink(
            path: path,
            contentType: contentType,
            ogTitle: ogTitle,
            ogImageUrl: ogImageUrl,
            ogDescription: ogDescription,
          );

          if (isOneLinkUrl(result)) {
            Logger.log('Deep link generated successfully: $result');
            return result;
          } else {
            Logger.warning('Invalid URL returned: $result');
            throw Exception('Invalid URL returned: $result');
          }
        },
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 200),
        maxDelay: const Duration(milliseconds: 300),
        onRetry: (error) {
          Logger.log('Retrying deep link generation due to: $error');
        },
      );
    } catch (error) {
      Logger.error(
        'Deep link generation failed after all retries: $error',
      );
      return fallbackUrl;
    }
  }

  Future<String> _generateInviteLink({
    required String path,
    SharedContentType? contentType,
    String? ogTitle,
    String? ogImageUrl,
    String? ogDescription,
  }) async {
    final completer = Completer<String>();

    try {
      _appsflyerSdk.generateInviteLink(
        AppsFlyerInviteLinkParams(
          brandDomain: _brandDomain,
          customParams: {
            'deep_link_value': path,
            if (contentType != null) _contentTypeKey: contentType.value,
            ...?_buildOgParams(
              ogTitle: ogTitle,
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
        return fallbackUrl;
      },
    );
  }

  Map<String, String>? _buildOgParams({
    String? ogTitle,
    String? ogImageUrl,
    String? ogDescription,
  }) {
    // Covers the case when deep link is being used for the reporting
    if (ogImageUrl == null && ogDescription == null && ogTitle == null) {
      return null;
    }

    // https://support.appsflyer.com/hc/en-us/articles/207447163-About-link-structure-and-parameters#af_og_title
    const maxOpenGraphTitleLength = 40;
    // https://support.appsflyer.com/hc/en-us/articles/207447163-About-link-structure-and-parameters#af_og_description
    const maxOpenGraphDescriptionLength = 300;

    // AppsFlyer requires a non-null or empty description because otherwise all og params will be not set at all
    final description = ogDescription.isEmpty
        ? ' '
        : _truncateText(text: ogDescription!, maxLength: maxOpenGraphDescriptionLength);
    final image = ogImageUrl.isEmpty ? ' ' : ogImageUrl!;

    if (ogTitle case final title?) {
      return {
        'af_og_title': _truncateText(text: title, maxLength: maxOpenGraphTitleLength),
        'af_og_description': description,
        'af_og_image': image,
      };
    }

    return null;
  }

  String _truncateText({required String text, required int maxLength}) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength);
    }
    return text;
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
        completer.complete(fallbackUrl);
      }
    } catch (error) {
      Logger.error('Deep link parsing error: $error');
      completer.complete(fallbackUrl);
    }
  }

  void _handleInviteLinkError(dynamic error, Completer<String> completer, String context) {
    if (completer.isCompleted) {
      return;
    }

    Logger.error('AppsFlyer invite link generation error ($context), $error');
    completer.complete(fallbackUrl);
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

  SharedContentType? _extractContentTypeFromLink(DeepLinkResult link) {
    try {
      final clickEvent = link.deepLink?.clickEvent;
      if (clickEvent != null) {
        final contentTypeValue = clickEvent[_contentTypeKey] as String?;
        if (contentTypeValue != null) {
          return SharedContentType.fromValue(contentTypeValue);
        }
      }
    } catch (e) {
      Logger.error('Error extracting content type from link: $e');
      rethrow;
    }
    return null;
  }
}
