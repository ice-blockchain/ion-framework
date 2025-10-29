// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_content_labeler_provider.r.g.dart';

class ContentLanguage {
  const ContentLanguage({required this.value});
  final String value;
}

class DetectedContentLanguage extends ContentLanguage {
  const DetectedContentLanguage({
    required super.value,
    required this.score,
    required this.confident,
  });
  final double score;
  final bool confident;
}

class IonContentLabeler {
  IonContentLabeler({
    required IONTextLabeler labeler,
    required double relevantThreshold,
    required double confidentThreshold,
  })  : _labeler = labeler,
        _relevantThreshold = relevantThreshold,
        _confidentThreshold = confidentThreshold;

  final IONTextLabeler _labeler;
  final double _relevantThreshold;
  final double _confidentThreshold;

  Future<DetectedContentLanguage?> detectLanguageLabels(String content) async {
    if (content.trim().length < 2) {
      return null;
    }
    try {
      final detectionResults = await _labeler.detect(
        content,
        model: TextLabelerModel.language,
      );
      Logger.log(
        '[Content Labeler] language labels: ${detectionResults.labels}, input: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}',
      );
      final bestResult = detectionResults.labels.firstOrNull;
      if (bestResult != null && bestResult.score >= _relevantThreshold) {
        return DetectedContentLanguage(
          value: bestResult.name,
          score: bestResult.score,
          confident: bestResult.score >= _confidentThreshold,
        );
      }
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: '[Content Labeler] detectLanguageLabels failed');
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
Future<IonContentLabeler> ionContentLabeler(Ref ref) async {
  final feedConfig = await ref.read(feedConfigProvider.future);
  return IonContentLabeler(
    labeler: IONTextLabeler(),
    relevantThreshold: 0.3,
    confidentThreshold: feedConfig.langDetectScoreThreshold,
  );
}
