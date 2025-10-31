// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/services/ion_content_labeler/ion_content_labeler_provider.r.dart';

class EntityLanguageModal extends HookConsumerWidget {
  const EntityLanguageModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState(ref.watch(selectedEntityLanguageNotifierProvider)?.value);

    return LanguageSelectorPage(
      title: context.i18n.common_select_language,
      description: context.i18n.select_post_language_description,
      toggleLanguageSelection: (langCode) {
        selectedLanguage.value = langCode;
      },
      selectedLanguages: selectedLanguage.value != null ? [selectedLanguage.value!] : [],
      appBar: NavigationAppBar.modal(
        onBackPress: () => context.pop(),
        actions: [NavigationCloseButton(onPressed: context.pop)],
      ),
      continueButton: Button(
        label: Text(context.i18n.button_continue),
        mainAxisSize: MainAxisSize.max,
        onPressed: () {
          final selected = selectedLanguage.value;
          ref.read(selectedEntityLanguageNotifierProvider.notifier).langLabel =
              selected != null ? ContentLanguage(value: selected) : null;
          context.pop();
        },
      ),
    );
  }
}
