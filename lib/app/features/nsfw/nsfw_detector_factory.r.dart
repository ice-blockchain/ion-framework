// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nsfw_detector_factory.r.g.dart';

abstract class NsfwDetectorFactory {
  Future<NsfwDetector> create();
}

class DefaultNsfwDetectorFactory implements NsfwDetectorFactory {
  DefaultNsfwDetectorFactory({
    required this.blockThreshold,
  });

  final double blockThreshold;

  @override
  Future<NsfwDetector> create() => NsfwDetector.create(blockThreshold: blockThreshold);
}

@riverpod
Future<NsfwDetectorFactory> nsfwDetectorFactory(Ref ref) async {
  final feedConfig = await ref.watch(feedConfigProvider.future);

  return DefaultNsfwDetectorFactory(blockThreshold: feedConfig.nsfwBlockThreshold);
}
