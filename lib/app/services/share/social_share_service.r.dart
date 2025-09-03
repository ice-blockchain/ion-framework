// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/clipboard/clipboard.dart';
import 'package:ion/app/services/deep_link/deep_link_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';

part 'social_share_service.r.g.dart';

@riverpod
SocialShareService socialShareService(Ref ref) {
  final deepLinkService = ref.watch(deepLinkServiceProvider);
  return SocialShareService(deepLinkService);
}

class SocialShareService {
  SocialShareService(this._deepLinkService);

  final DeepLinkService _deepLinkService;

  Future<void> shareToWhatsApp(
    String shareUrl, {
    required String title,
    String? imageUrl,
    String? description,
  }) =>
      _shareToPlatform(
        SocialPlatform.whatsapp,
        shareUrl: shareUrl,
        title: title,
        imageUrl: imageUrl,
        description: description,
      );

  Future<void> shareToTwitter(
    String shareUrl, {
    required String title,
    String? imageUrl,
    String? description,
  }) =>
      _shareToPlatform(
        SocialPlatform.twitter,
        shareUrl: shareUrl,
        title: title,
        imageUrl: imageUrl,
        description: description,
      );

  Future<void> shareToTelegram(
    String shareUrl, {
    required String title,
    String? imageUrl,
    String? description,
  }) =>
      _shareToPlatform(
        SocialPlatform.telegram,
        shareUrl: shareUrl,
        title: title,
        imageUrl: imageUrl,
        description: description,
      );

  Future<void> _shareToPlatform(
    SocialPlatform platform, {
    required String shareUrl,
    required String title,
    String? imageUrl,
    String? description,
  }) async {
    final url = await _deepLinkService.createDeeplink(
      path: shareUrl,
      ogTitle: title,
      ogImageUrl: imageUrl,
      ogDescription: description,
    );
    await SocialSharingPlus.shareToSocialMedia(platform, url);
  }

  Future<void> shareToMore({
    required String shareUrl,
    required String title,
    String? imageUrl,
    String? description,
  }) async {
    final url = await _deepLinkService.createDeeplink(
      path: shareUrl,
      ogTitle: title,
      ogImageUrl: imageUrl,
      ogDescription: description,
    );
    await Share.share(url);
  }

  Future<void> shareToClipboard({
    required String shareUrl,
    required String title,
    String? imageUrl,
    String? description,
  }) async {
    final url = await _deepLinkService.createDeeplink(
      path: shareUrl,
      ogTitle: title,
      ogImageUrl: imageUrl,
      ogDescription: description,
    );
    copyToClipboard(url);
  }
}
