// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/tag_button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEntityLanguageCode = ref.watch(selectedEntityLanguageNotifierProvider);
    final selectedEntityLanguage = selectedEntityLanguageCode != null
        ? Language.fromIsoCode(selectedEntityLanguageCode)
        : null;

    return TagButton(
      onPressed: () => {},
      label: selectedEntityLanguage != null
          ? selectedEntityLanguage.displayName
          : selectedEntityLanguageCode ?? context.i18n.common_language,
      leadingIcon: Assets.svg.iconSelectLanguage.icon(
        color: context.theme.appColors.primaryAccent,
        size: 12.s,
      ),
    );
  }
}
