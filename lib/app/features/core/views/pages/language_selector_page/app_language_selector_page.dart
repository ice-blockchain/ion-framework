// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/core/providers/language_lists_provider.r.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page/language_selector_page.dart';

/// Language selector page specifically for app UI language selection.
///
/// This widget filters the language list to only show languages that are supported
/// by the app's localization system (based on I18n.supportedLocales).
class AppLanguageSelectorPage extends ConsumerWidget {
  const AppLanguageSelectorPage({
    required this.title,
    required this.description,
    this.appBar,
    this.continueButton,
    super.key,
  });

  final String title;
  final String description;
  final Widget? appBar;
  final Widget? continueButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get sorted supported languages from provider
    final sortedLanguages = ref.watch(appLanguagesListProvider);
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
