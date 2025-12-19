// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/clipboard/clipboard.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';

part 'social_share_service.r.g.dart';

@riverpod
SocialShareService socialShareService(Ref ref) {
  final appsflyerDeepLinkService = ref.watch(appsflyerDeepLinkServiceProvider);
  return SocialShareService(appsflyerDeepLinkService);
}

class SocialShareService {
  SocialShareService(this._appsflyerDeepLinkService);

  final AppsFlyerDeepLinkService _appsflyerDeepLinkService;

  Future<void> shareToWhatsApp(
    String shareUrl, {
    required String title,
    required SharedContentType contentType,
    String? imageUrl,
    String? description,
  }) =>
      _shareToPlatform(
        SocialPlatform.whatsapp,
        shareUrl: shareUrl,
        title: title,
        contentType: contentType,
        imageUrl: imageUrl,
        description: description,
      );

  Future<void> shareToTwitter(
    String shareUrl, {
    required String title,
    required SharedContentType contentType,
    String? imageUrl,
    String? description,
  }) =>
      _shareToPlatform(
        SocialPlatform.twitter,
        shareUrl: shareUrl,
        title: title,
        contentType: contentType,
        imageUrl: imageUrl,
        description: description,
      );

  Future<void> shareToTelegram(
    String shareUrl, {
    required String title,
    required SharedContentType contentType,
    String? imageUrl,
    String? description,
  }) =>
      _shareToPlatform(
        SocialPlatform.telegram,
        shareUrl: shareUrl,
        title: title,
        contentType: contentType,
        imageUrl: imageUrl,
        description: description,
      );

  Future<void> _shareToPlatform(
    SocialPlatform platform, {
    required String shareUrl,
    required String title,
    required SharedContentType contentType,
    String? imageUrl,
    String? description,
  }) async {
    final url = await _appsflyerDeepLinkService.createDeeplink(
      path: shareUrl,
      contentType: contentType,
      ogTitle: title,
      ogImageUrl: imageUrl,
      ogDescription: description,
    );
    await SocialSharingPlus.shareToSocialMedia(platform, url);
  }

  Future<void> shareToMore({
    required String shareUrl,
    required String title,
    required SharedContentType contentType,
    String? imageUrl,
    String? description,
  }) async {
    final url = await _appsflyerDeepLinkService.createDeeplink(
      path: shareUrl,
      contentType: contentType,
      ogTitle: title,
      ogImageUrl: imageUrl,
      ogDescription: description,
    );
    await Share.share(url);
  }

  Future<void> shareToClipboard({
    required String shareUrl,
    required String title,
    required SharedContentType contentType,
    String? imageUrl,
    String? description,
  }) async {
    final url = await _appsflyerDeepLinkService.createDeeplink(
      path: shareUrl,
      contentType: contentType,
      ogTitle: title,
      ogImageUrl: imageUrl,
      ogDescription: description,
    );
    copyToClipboard(url);
  }
}
