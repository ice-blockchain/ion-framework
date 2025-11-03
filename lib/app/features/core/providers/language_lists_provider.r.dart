// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_lists_provider.r.g.dart';

/// Provides supported app languages sorted with preferred languages at the top.
///
/// This is specifically for the app language selector. It uses [localePreferredLanguagesProvider]
/// to determine which languages should appear first (app locale, system locale, English).
///
/// The list is captured once when first accessed and won't change during the session,
/// preventing the list from re-sorting when the user selects a language.
@Riverpod(keepAlive: true)
List<Language> appLanguagesList(Ref ref) {
  final supportedLanguageCodes =
      I18n.supportedLocales.map((locale) => locale.languageCode.toLowerCase()).toSet();
  final supportedLangs = Language.values
      .where((language) => supportedLanguageCodes.contains(language.isoCode.toLowerCase()))
      .toList();

  // Get preferred languages from locale provider (includes app locale, system locale, English)
  final preferredLanguages = ref.read(localePreferredLanguagesProvider);

  if (preferredLanguages.isEmpty) return supportedLangs;

  final languagesSet = {...supportedLangs}..removeAll(preferredLanguages);
  return languagesSet.toList()..insertAll(0, preferredLanguages);
}

/// Provides all languages sorted with preferred languages at the top.
///
/// This is specifically for content language selection where all languages should be available.
/// If [customPreferredLanguages] is provided, it uses those; otherwise it uses
/// [localePreferredContentLanguagesProvider] (system locale, English).
@riverpod
List<Language> contentLanguagesList(
  Ref ref, {
  List<Language>? preferredLanguages,
}) {
  // Get preferred languages for content (includes system locale and English)
  final localePreferredLanguages = ref.watch(localePreferredContentLanguagesProvider);
  final preferredLangs = preferredLanguages ?? localePreferredLanguages;

  if (preferredLangs.isEmpty) return Language.values;

  final languagesSet = {...Language.values}..removeAll(preferredLangs);
  return languagesSet.toList()..insertAll(0, preferredLangs);
}
