// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_categories_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class CategorySelectModal extends HookConsumerWidget {
  const CategorySelectModal({
    required this.selectedCategory,
    super.key,
  });

  final String? selectedCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(userCategoriesProvider);
    final searchValue = useState('');
    final filteredCategories = useMemoized(
      () {
        final query = searchValue.value.toLowerCase();
        return categories.values.where((category) {
          return category.getName(context).toLowerCase().contains(query);
        }).toList();
      },
      [categories, searchValue.value],
    );

    return SheetContent(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            primary: false,
            flexibleSpace: NavigationAppBar.modal(
              showBackButton: false,
              actions: [
                NavigationCloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              title: Text(context.i18n.dapps_section_title_categories),
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: NavigationAppBar.modalHeaderHeight,
            pinned: true,
          ),
          PinnedHeaderSliver(
            child: ColoredBox(
              color: context.theme.appColors.onPrimaryAccent,
              child: Column(
                children: [
                  SizedBox(height: 16.0.s),
                  ScreenSideOffset.small(
                    child: SearchInput(
                      onTextChanged: (String value) {
                        searchValue.value = value;
                      },
                    ),
                  ),
                  SizedBox(height: 8.0.s),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final category = filteredCategories[index];
                return ListItem(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 8.0.s),
                  constraints: const BoxConstraints(),
                  backgroundColor: context.theme.appColors.secondaryBackground,
                  onTap: () => Navigator.of(context).pop(category.key),
                  title: Text(category.getName(context), style: context.theme.appTextThemes.body),
                  trailing: selectedCategory == category.key
                      ? Assets.svg.iconBlockCheckboxOnblue.icon(
                          color: context.theme.appColors.success,
                        )
                      : Assets.svg.iconBlockCheckboxOff.icon(
                          color: context.theme.appColors.tertiaryText,
                        ),
                );
              },
              childCount: filteredCategories.length,
            ),
          ),
        ],
      ),
    );
  }
}
