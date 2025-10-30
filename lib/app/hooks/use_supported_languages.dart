// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/generated/app_localizations.dart';

/// A hook that filters a list of languages to only include those supported by the app.
///
/// This hook is useful when selecting the app's UI language, as opposed to content languages.
/// It filters based on [I18n.supportedLocales].
List<Language> useSupportedLanguages(List<Language> languages) {
  return useMemoized(
    () {
      final supportedLanguageCodes =
          I18n.supportedLocales.map((locale) => locale.languageCode.toLowerCase()).toSet();

      return languages
          .where((language) => supportedLanguageCodes.contains(language.isoCode.toLowerCase()))
          .toList();
    },
    [languages],
  );
}
