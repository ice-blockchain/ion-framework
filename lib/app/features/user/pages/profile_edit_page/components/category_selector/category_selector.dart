// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_categories_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class CategorySelector extends HookConsumerWidget {
  const CategorySelector({
    required this.selectedCategory,
    required this.onChanged,
    super.key,
  });

  final ValueChanged<String>? onChanged;
  final String? selectedCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState(selectedCategory);
    final categories = ref.watch(userCategoriesProvider);

    final label = selected.value != null
        ? (categories[selected.value]?.getName(context) ?? selectedCategory!)
        : context.i18n.dropdown_select_category;

    return Button.dropdown(
      useDefaultBorderRadius: true,
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 14.0.s,
      ),
      backgroundColor: context.theme.appColors.secondaryBackground,
      borderColor: context.theme.appColors.strokeElements,
      leadingIcon: ButtonIconFrame(
        containerSize: 30.0.s,
        color: context.theme.appColors.tertiaryBackground,
        icon: Assets.svg.iconBlockchain.icon(
          size: 20.0.s,
          color: context.theme.appColors.secondaryText,
        ),
        border: Border.fromBorderSide(
          BorderSide(color: context.theme.appColors.onTertiaryFill, width: 1.0.s),
        ),
      ),
      label: SizedBox(
        width: double.infinity,
        child: Text(label),
      ),
      onPressed: () async {
        final newCategory = await CategorySelectRoute(
          selectedCategory: selected.value,
        ).push<String?>(context);
        if (newCategory != null) {
          selected.value = newCategory;
          onChanged?.call(newCategory);
        }
      },
    );
  }
}
