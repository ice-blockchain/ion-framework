// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/utils/debounced_quill_controller_listener.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/app/services/ion_content_labeler/ion_content_labeler_provider.r.dart';

const languageDetectionThreshold = 0.3;

void useDetectLanguage(
  WidgetRef ref, {
  required QuillController? textEditorController,
}) {
  final labeler = ref.read(ionContentLabelerProvider);
  useEffect(
    () {
      if (textEditorController != null) {
        final subscription = debouncedQuillControllerListener(
          textEditorController,
          duration: const Duration(seconds: 1),
        ).listen((text) async {
          final detectedLanguage = await labeler.detectLanguageLabels(text);
          if (detectedLanguage != null) {
            ref.read(selectedEntityLanguageNotifierProvider.notifier).lang = detectedLanguage;
          }
        });
        return subscription.cancel;
      }
      return null;
    },
    [textEditorController],
  );
}
