// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page/app_language_selector_page.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class AppLanguageModal extends ConsumerWidget {
  const AppLanguageModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);

    return AppLanguageSelectorPage(
      title: context.i18n.app_language_title,
      description: context.i18n.app_language_description,
      toggleLanguageSelection: (languageCode) {
        ref.read(appLocaleProvider.notifier).locale = Locale(languageCode);
      },
      selectedLanguages: [locale.languageCode.toLowerCase()],
      appBar: NavigationAppBar.modal(
        onBackPress: () => context.pop(true),
        actions: const [NavigationCloseButton()],
      ),
    );
  }
}
