// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/back_hardware_button_interceptor/back_hardware_button_interceptor.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/language_selector_page/content_language_selector_page.dart';
import 'package:ion/app/features/optimistic_ui/features/language/language_sync_strategy_provider.r.dart';
import 'package:ion/app/hooks/use_selected_state.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class ContentLanguageModal extends HookConsumerWidget {
  const ContentLanguageModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSelectedLanguages = ref.watch(
      contentLanguageWatchProvider.select(
        (async) => async.valueOrNull?.hashtags ?? const <String>[],
      ),
    );

    // Track selected languages locally (only update when modal closes)
    final (selectedLanguages, toggleLanguageSelection) = useSelectedState<String>(
      currentSelectedLanguages,
    );

    final applyChanges = useCallback(
      () async {
        final updateNotifier = ref.read(updateContentLanguagesNotifierProvider.notifier);
        await updateNotifier.update(selectedLanguages);
      },
      [selectedLanguages, ref],
    );

    //needs a callback for BackHardwareButtonInterceptor, otherwise it uses only the initial snapshot
    final handleBackPress = useCallback(
      (BuildContext context) async {
        await applyChanges();
        if (context.mounted) {
          context.pop(true);
        }
      },
      [applyChanges],
    );

    return BackHardwareButtonInterceptor(
      onBackPress: handleBackPress,
      child: ContentLanguageSelectorPage(
        title: context.i18n.content_language_title,
        description: context.i18n.content_language_description,
        toggleLanguageSelection: toggleLanguageSelection,
        selectedLanguages: selectedLanguages,
        appBar: NavigationAppBar.modal(
          onBackPress: () => unawaited(handleBackPress(context)),
          actions: [
            NavigationCloseButton(
              onPressed: () => unawaited(handleBackPress(context)),
            ),
          ],
        ),
      ),
    );
  }
}
