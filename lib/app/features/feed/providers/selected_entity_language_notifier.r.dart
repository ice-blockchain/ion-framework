// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_entity_language_notifier.r.g.dart';

@riverpod
class SelectedEntityLanguageNotifier extends _$SelectedEntityLanguageNotifier {
  @override
  String? build() {
    return null;
  }

  set lang(String? lang) {
    state = lang;
  }
}
