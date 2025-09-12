// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_content_labeler_provider.r.g.dart';

const _languageDetectionThreshold = 0.3;

class IonContentLabeler {
  IonContentLabeler({required IONTextLabeler labeler}) : _labeler = labeler;

  final IONTextLabeler _labeler;

  Future<String?> detectLanguageLabels(String content) async {
    final detectionResults = await _labeler.detect(
      content,
      model: TextLabelerModel.language,
    );
    Logger.log(
      '[Content Labeler] language labels: ${detectionResults.labels}, input: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}',
    );
    final bestResult = detectionResults.labels.firstOrNull;
    if (content.isNotEmpty &&
        bestResult != null &&
        bestResult.score > _languageDetectionThreshold) {
      return bestResult.name;
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
IonContentLabeler ionContentLabeler(Ref ref) {
  return IonContentLabeler(labeler: IONTextLabeler());
}
