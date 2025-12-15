// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'internal_deep_link_service.r.g.dart';

/// Service for handling internal deep links with the ionapp:// scheme
///
/// Supports the following deep link patterns:
/// - ionapp://feed - Opens the feed tab
/// - ionapp://chat - Opens the chat tab
/// - ionapp://wallet - Opens the wallet tab
/// - ionapp://profile - Opens the profile tab
/// - ionapp://invite - Opens the invite friends page
@Riverpod(keepAlive: true)
InternalDeepLinkService internalDeepLinkService(Ref ref) {
  return InternalDeepLinkService();
}

final class InternalDeepLinkService {
  static const String scheme = 'ionapp';

  /// Checks if the given URL is an internal deep link
  bool isInternalDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.toLowerCase() == scheme;
    } catch (e) {
      Logger.error('Error parsing URL: $url, error: $e');
      return false;
    }
  }

  /// Handles an internal deep link by navigating to the appropriate route
  ///
  /// Returns true if the deep link was handled successfully, false otherwise
  Future<bool> handleInternalDeepLink(String url, BuildContext context) async {
    if (!isInternalDeepLink(url)) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      final path = uri.host.toLowerCase();

      switch (path) {
        case 'feed':
          FeedRoute().go(context);
        case 'chat':
          ChatRoute().go(context);
        case 'wallet':
          WalletRoute().go(context);
        case 'profile':
          SelfProfileRoute().go(context);
        case 'invite':
          InviteFriendsRoute().go(context);
        default:
          Logger.warning('Unsupported internal deep link path: $path');
          return false;
      }

      Logger.log('Internal deep link handled: $url');
      return true;
    } catch (error) {
      Logger.error('Error handling internal deep link: $url, error: $error');
      return false;
    }
  }
}
