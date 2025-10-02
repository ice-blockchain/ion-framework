// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nsfw_detector_factory.r.g.dart';

abstract class NsfwDetectorFactory {
  Future<NsfwDetector> create();
}

class DefaultNsfwDetectorFactory implements NsfwDetectorFactory {
  @override
  Future<NsfwDetector> create() => NsfwDetector.create();
}

@riverpod
NsfwDetectorFactory nsfwDetectorFactory(Ref ref) => DefaultNsfwDetectorFactory();
