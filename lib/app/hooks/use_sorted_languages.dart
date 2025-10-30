// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/core/model/language.dart';

/// A hook that returns a sorted list of languages with preferred languages at the top.
///
/// If [preferredLangs] are provided, they are moved to the top of the list,
/// followed by all other languages.
List<Language> useSortedLanguages({
  List<Language> languages = Language.values,
  List<Language> preferredLangs = const [],
}) {
  return useMemoized(
    () {
      if (preferredLangs.isEmpty) return languages;
      final languagesSet = {...languages}..removeAll(preferredLangs);
      return languagesSet.toList()..insertAll(0, preferredLangs);
    },
    [languages, preferredLangs],
  );
}
