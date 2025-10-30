// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page/language_selector_page.dart';
import 'package:ion/app/hooks/use_sorted_languages.dart';
import 'package:ion/app/hooks/use_supported_languages.dart';

/// Language selector page specifically for app UI language selection.
///
/// This widget filters the language list to only show languages that are supported
/// by the app's localization system (based on I18n.supportedLocales).
class AppLanguageSelectorPage extends HookConsumerWidget {
  const AppLanguageSelectorPage({
    required this.title,
    required this.description,
    required this.selectedLanguages,
    required this.toggleLanguageSelection,
    this.appBar,
    this.continueButton,
    this.preferredLanguages,
    super.key,
  });

  final String title;
  final String description;
  final Widget? appBar;
  final Widget? continueButton;
  final List<String> selectedLanguages;
  final List<Language>? preferredLanguages;
  final void Function(String) toggleLanguageSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get preferred languages for app locale (includes app locale, system locale, and English)
    final localePreferredLanguages = ref.watch(localePreferredLanguagesProvider);
    final preferredLangs = preferredLanguages ?? localePreferredLanguages;

    // Filter to only show supported app languages
    final supportedLanguages = useSupportedLanguages(Language.values);

    // Sort with preferred languages at the top
    final sortedLanguages = useSortedLanguages(
      languages: supportedLanguages,
      preferredLangs: preferredLangs,
    );

    return LanguageSelectorPage(
      title: title,
      description: description,
      selectedLanguages: selectedLanguages,
      toggleLanguageSelection: toggleLanguageSelection,
      languages: sortedLanguages,
      appBar: appBar,
      continueButton: continueButton,
    );
  }
}
