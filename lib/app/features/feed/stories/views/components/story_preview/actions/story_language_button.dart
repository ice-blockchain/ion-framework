// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class StoryLanguageButton extends HookConsumerWidget {
  const StoryLanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEntityLanguageCode = ref.watch(selectedEntityLanguageNotifierProvider);
    final selectedEntityLanguage = selectedEntityLanguageCode != null
        ? Language.fromIsoCode(selectedEntityLanguageCode.value)
        : null;

    return ListItem(
      title: Text(
        selectedEntityLanguage != null
            ? selectedEntityLanguage.displayName
            : selectedEntityLanguageCode?.value ?? context.i18n.common_language,
        style: context.theme.appTextThemes.caption.copyWith(
          color: context.theme.appColors.primaryAccent,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      backgroundColor: context.theme.appColors.secondaryBackground,
      leading: Assets.svg.iconSelectLanguage.icon(
        color: context.theme.appColors.primaryAccent,
        size: 24.s,
      ),
      trailing: Assets.svg.iconArrowRight.icon(
        color: context.theme.appColors.primaryAccent,
        size: 16.s,
      ),
      constraints: BoxConstraints(minHeight: 40.0.s),
      onTap: () {
        EntityLanguageRoute().push<void>(context);
      },
    );
  }
}
