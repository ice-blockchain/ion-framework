// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/settings/model/content_lang_set.f.dart';

class UpdateLanguagesIntent implements OptimisticIntent<ContentLangSet> {
  UpdateLanguagesIntent(this.languageCodes);
  final List<String> languageCodes;

  @override
  ContentLangSet optimistic(ContentLangSet current) {
    return current.copyWith(hashtags: languageCodes).sorted;
  }

  @override
  Future<ContentLangSet> sync(ContentLangSet prev, ContentLangSet next) async => next;
}
