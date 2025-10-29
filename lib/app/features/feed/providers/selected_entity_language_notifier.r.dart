// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/ion_content_labeler/ion_content_labeler_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_entity_language_notifier.r.g.dart';

@riverpod
class SelectedEntityLanguageNotifier extends _$SelectedEntityLanguageNotifier {
  @override
  ContentLanguage? build() {
    return null;
  }

  set langLabel(ContentLanguage? langLabel) {
    state = langLabel;
  }
}
