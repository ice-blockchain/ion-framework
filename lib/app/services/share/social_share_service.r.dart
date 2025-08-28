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
    required String userDisplayName,
    String? content,
    String? imageUrl,
  }) =>
      _shareToPlatform(
        SocialPlatform.whatsapp,
        shareUrl: shareUrl,
        userDisplayName: userDisplayName,
        content: content,
        imageUrl: imageUrl,
      );

  Future<void> shareToTwitter(
    String shareUrl, {
    required String userDisplayName,
    String? content,
    String? imageUrl,
  }) =>
      _shareToPlatform(
        SocialPlatform.twitter,
        shareUrl: shareUrl,
        userDisplayName: userDisplayName,
        content: content,
        imageUrl: imageUrl,
      );

  Future<void> shareToTelegram(
    String shareUrl, {
    required String userDisplayName,
    String? content,
    String? imageUrl,
  }) =>
      _shareToPlatform(
        SocialPlatform.telegram,
        shareUrl: shareUrl,
        userDisplayName: userDisplayName,
        content: content,
        imageUrl: imageUrl,
      );

  Future<void> _shareToPlatform(
    SocialPlatform platform, {
    required String shareUrl,
    required String userDisplayName,
    String? content,
    String? imageUrl,
  }) async {
    final url = await _deepLinkService.createDeeplink(
      path: shareUrl,
      userDisplayName: userDisplayName,
      content: content,
      imageUrl: imageUrl,
    );
    await SocialSharingPlus.shareToSocialMedia(platform, url);
  }

  Future<void> shareToMore({
    required String shareUrl,
    required String userDisplayName,
    String? content,
    String? imageUrl,
  }) async {
    final url = await _deepLinkService.createDeeplink(
      path: shareUrl,
      userDisplayName: userDisplayName,
      content: content,
      imageUrl: imageUrl,
    );
    await Share.share(url);
  }

  Future<void> shareToClipboard({
    required String shareUrl,
    required String userDisplayName,
    String? content,
    String? imageUrl,
  }) async {
    final url = await _deepLinkService.createDeeplink(
      path: shareUrl,
      userDisplayName: userDisplayName,
      content: content,
      imageUrl: imageUrl,
    );
    copyToClipboard(url);
  }
}
