// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'url_metadata_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<OgpData?> urlMetadata(Ref ref, String url) async {
  final uri = Uri.tryParse(url);

  if (uri == null || uri.scheme.isEmpty) {
    return null;
  }

  try {
    // Using this agent because AppsFlyer generates meta data for certain social media apps.
    // link: https://support.appsflyer.com/hc/en-us/articles/208874366-Create-a-OneLink-link-for-your-campaigns#social-media-preview-og-tags
    return await OgpDataExtract.execute(url, userAgent: 'TelegramBot (like TwitterBot)');
  } catch (e) {
    return null;
  }
}
