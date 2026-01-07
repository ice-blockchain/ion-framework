// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/app/features/core/providers/language_lists_provider.r.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page/language_selector_page.dart';

/// Language selector page specifically for content language selection.
///
/// This widget shows all available languages, not just those supported by the app's
/// localization system. Use this for selecting content languages, post languages, etc.
class ContentLanguageSelectorPage extends HookConsumerWidget {
  const ContentLanguageSelectorPage({
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
    // Get sorted content languages from provider
    // Can optionally pass custom preferred languages (e.g., during onboarding)
    final sortedLanguages = ref.watch(
      contentLanguagesListProvider(preferredLanguages: preferredLanguages),
    );

    // Sort languages so selected ones appear at the top
    final languagesWithSelectedFirst = useMemoized(
      () => _sortWithSelectedFirst(sortedLanguages, selectedLanguages),
      [],
    );

    return LanguageSelectorPage(
      title: title,
      description: description,
      selectedLanguages: selectedLanguages,
      toggleLanguageSelection: toggleLanguageSelection,
      languages: languagesWithSelectedFirst,
      appBar: appBar,
      continueButton: continueButton,
    );
  }

  /// Sorts languages so selected languages appear first.
  List<Language> _sortWithSelectedFirst(
    List<Language> languages,
    List<String> selectedLanguageCodes,
  ) {
    if (selectedLanguageCodes.isEmpty) return languages;

    final selectedLanguagesMap = {
      for (final code in selectedLanguageCodes) code.toLowerCase(): true,
    };

    final selected = <Language>[];
    final unselected = <Language>[];

    for (final language in languages) {
      if (selectedLanguagesMap[language.isoCode.toLowerCase()] ?? false) {
        selected.add(language);
      } else {
        unselected.add(language);
      }
    }

    return [...selected, ...unselected];
  }
}
