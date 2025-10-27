// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:ion/app/services/deep_link/deep_link_service.r.dart';

String? removeHttpsPrefix(String? url) {
  // Replace the https:// prefix with an empty string if it exists.
  return url?.replaceFirst(RegExp('^https://'), '');
}

String? extractDomain(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host;
  } catch (_) {}
  return null;
}

String normalizeUrl(String url) {
  // Remove leading/trailing whitespace
  var normalizedUrl = url.trim();

  // Remove any mailto: prefix
  if (normalizedUrl.startsWith('mailto:')) {
    return normalizedUrl;
  }

  // Handle common messenger/social media protocols
  if (normalizedUrl.startsWith(RegExp('^(tg|fb|twitter|whatsapp)://'))) {
    return normalizedUrl;
  }

  // Remove multiple forward slashes except for protocol
  normalizedUrl = normalizedUrl.replaceAll(RegExp('([^:])//+'), r'$1/');

  // Handle protocol-relative URLs (starting with //)
  if (normalizedUrl.startsWith('//')) {
    return 'https:$normalizedUrl';
  }

  // Add https:// if no protocol is present
  if (!normalizedUrl.startsWith(RegExp('^[a-zA-Z]+://'))) {
    // Remove any leading slashes before adding https://
    normalizedUrl = normalizedUrl.replaceAll(RegExp('^/+'), '');
    normalizedUrl = 'https://$normalizedUrl';
  }

  return normalizedUrl;
}

String resolveImageUrl(String baseUrl, String imageUrl) {
  return imageUrl.startsWith('/')
      ? Uri.parse(Uri.parse(baseUrl).origin + imageUrl).toString()
      : imageUrl;
}

bool isNetworkUrl(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}

final _mediaIdRegex = RegExp(r'^[0-9a-f]{64}:[0-9a-f]{64}\.[a-z0-9]+$', caseSensitive: false);

bool isIonMediaUrl(String url) {
  return isNetworkUrl(url) && _mediaIdRegex.hasMatch(url);
}

bool isOneLinkUrl(String url) {
  return DeepLinkService.oneLinkUrlRegex.hasMatch(url);
}

/// Returns `false` If [address] is not a numeric IPv4 (dotted-decimal
/// notation) or IPv6 (hexadecimal representation) address
bool isIP(String address) => InternetAddress.tryParse(address) != null;
