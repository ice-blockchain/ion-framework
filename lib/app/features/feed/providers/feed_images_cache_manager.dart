// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ion/app/services/file_cache/ion_http_file_service.dart';

class FeedImagesCacheManager {
  static late final CacheManager instance;
  static bool _initialized = false;

  static const key = 'feedImagesCacheKey';

  static void init({required int maxConcurrentDownloads}) {
    if (_initialized) return;
    final config = Config(
      key,
      fileService: IonHttpFileService(concurrentFetches: maxConcurrentDownloads),
      stalePeriod: const Duration(days: 1),
      maxNrOfCacheObjects: 1000,
    );

    instance = CacheManager(
      config,
    );
    _initialized = true;
  }
}
