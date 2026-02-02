// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/services/file_cache/ion_http_file_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'story_image_loading_provider.r.g.dart';

const _kStoryCacheKey = 'story_image_cache';

/// A provider to track loading states for story images
@riverpod
class StoryImageLoadStatus extends _$StoryImageLoadStatus {
  @override
  bool build(String storyId) => false;

  void markLoaded() => state = true;
}

@Riverpod(keepAlive: true)
BaseCacheManager storyImageCacheManager(Ref ref) {
  final expirationHours =
      ref.watch(envProvider.notifier).get<int>(EnvVariable.STORY_EXPIRATION_HOURS);

  return CacheManager(
    Config(
      _kStoryCacheKey,
      stalePeriod: Duration(hours: expirationHours),
      maxNrOfCacheObjects: 100,
      fileService: IonHttpFileService(),
    ),
  );
}
