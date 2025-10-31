// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
    this.appBar,
    this.continueButton,
    this.preferredLanguages,
    super.key,
  });

  final String title;
  final String description;
  final Widget? appBar;
  final Widget? continueButton;
  final List<Language>? preferredLanguages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Capture preferred languages only once when screen is first built
    // This prevents the list from re-sorting when the user selects a language
    final localePreferredLanguages = useMemoized(
      () => ref.read(localePreferredLanguagesProvider),
      [], // Empty dependencies = only compute once
    );
    final preferredLangs = preferredLanguages ?? localePreferredLanguages;

    // Filter to only show supported app languages
    final supportedLanguages = useSupportedLanguages(Language.values);

    final sortedLanguages = useSortedLanguages(
      languages: supportedLanguages,
      preferredLangs: preferredLangs,
    );

    final locale = ref.watch(appLocaleProvider);

    return LanguageSelectorPage(
      title: title,
      description: description,
      selectedLanguages: [locale.languageCode.toLowerCase()],
      toggleLanguageSelection: (languageCode) {
        ref.read(appLocaleProvider.notifier).locale = Locale(languageCode);
      },
      languages: sortedLanguages,
      appBar: appBar,
      continueButton: continueButton,
    );
  }
}
