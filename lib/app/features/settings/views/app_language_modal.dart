// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page/app_language_selector_page.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class AppLanguageModal extends StatelessWidget {
  const AppLanguageModal({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLanguageSelectorPage(
      title: context.i18n.app_language_title,
      description: context.i18n.app_language_description,
      appBar: NavigationAppBar.modal(
        onBackPress: () => context.pop(true),
        actions: const [NavigationCloseButton()],
      ),
    );
  }
}
