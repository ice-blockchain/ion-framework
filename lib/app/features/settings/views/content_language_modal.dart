// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page/content_language_selector_page.dart';
import 'package:ion/app/features/optimistic_ui/features/language/language_sync_strategy_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class ContentLanguageModal extends HookConsumerWidget {
  const ContentLanguageModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguages = ref.watch(
      contentLanguageWatchProvider.select(
        (async) => async.valueOrNull?.hashtags ?? const <String>[],
      ),
    );

    return ContentLanguageSelectorPage(
      title: context.i18n.content_language_title,
      description: context.i18n.content_language_description,
      toggleLanguageSelection: (iso) =>
          ref.read(toggleLanguageNotifierProvider.notifier).toggle(iso),
      selectedLanguages: selectedLanguages,
      appBar: NavigationAppBar.modal(
        onBackPress: () => context.pop(true),
        actions: const [NavigationCloseButton()],
      ),
    );
  }
}
