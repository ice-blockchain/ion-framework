// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/url.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openUrl(
  String url, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  final uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: mode);
    } else {
      return false;
    }
  } catch (error) {
    Logger.log('Could not launch $url', error: error);
    return false;
  }
}

Future<bool> openUrlInAppBrowser(String url) async {
  return openUrl(url, mode: LaunchMode.inAppBrowserView);
}

Future<bool> openDeepLinkOrInAppBrowser(String url, WidgetRef ref) async {
  if (isOneLinkUrl(url)) {
    ref.read(appsflyerDeepLinkServiceProvider).resolveDeeplink(url);
    return true;
  }

  return openUrlInAppBrowser(normalizeUrl(url));
}
