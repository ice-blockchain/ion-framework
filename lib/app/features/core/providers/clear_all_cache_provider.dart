// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_images_cache_manager.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';

final clearAllCacheProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(ionConnectCacheProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);
    await cacheService.clearDatabase();

    await Future.wait([
      IONCacheManager.instance.emptyCache(),
      IONCacheManager.ionNetworkImage.emptyCache(),
      IONCacheManager.ionConnectNetworkImage.emptyCache(),
      IONCacheManager.networkVideos.emptyCache(),
      IONCacheManager.preCachePictures.emptyCache(),
    ]);

    try {
      await FeedImagesCacheManager.instance.emptyCache();
    } catch (_) {}

    ref.invalidate(tradeCommunityTokenRepositoryProvider);
  };
});
