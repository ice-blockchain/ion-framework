// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class EntityLanguageModal extends ConsumerWidget {
  const EntityLanguageModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(selectedEntityLanguageNotifierProvider);

    return LanguageSelectorPage(
      title: context.i18n.content_language_title,
      description: context.i18n.content_language_description,
      toggleLanguageSelection: (iso) {
        ref.read(selectedEntityLanguageNotifierProvider.notifier).lang = iso;
        context.pop();
      },
      selectedLanguages: selectedLanguage != null ? [selectedLanguage] : [],
      appBar: NavigationAppBar.modal(
        onBackPress: () => context.pop(),
        actions: [NavigationCloseButton(onPressed: context.pop)],
      ),
    );
  }
}
