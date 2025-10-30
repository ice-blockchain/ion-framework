// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_header.dart';
import 'package:ion/app/features/auth/views/pages/select_languages/language_list_item.dart';
import 'package:ion/app/features/core/model/language.dart';
import 'package:ion/app/hooks/use_filtered_languages.dart';
import 'package:ion/app/hooks/use_measured_widget_height.dart';
import 'package:ion/app/router/components/navigation_app_bar/collapsing_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

/// Base language selector page that displays a list of languages.
///
/// This widget is a generic language selector that accepts a pre-filtered list of languages.
/// For specific use cases, consider using:
/// - [AppLanguageSelectorPage] for app UI language selection (only supported locales)
/// - [ContentLanguageSelectorPage] for content language selection (all available languages)
class LanguageSelectorPage extends HookConsumerWidget {
  const LanguageSelectorPage({
    required this.title,
    required this.description,
    required this.selectedLanguages,
    required this.toggleLanguageSelection,
    required this.languages,
    this.appBar,
    this.continueButton,
    super.key,
  });

  final String title;
  final String description;
  final Widget? appBar;
  final Widget? continueButton;
  final List<String> selectedLanguages;
  final List<Language> languages;
  final void Function(String) toggleLanguageSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final filteredLanguages = useFilteredLanguages(
      languages: languages,
      query: searchQuery.value,
    );

    final mayContinue = selectedLanguages.isNotEmpty;
    final renderBottomBar = mayContinue && continueButton != null;

    final (bottomBarKey, bottomBarHeight) = useMeasuredWidgetHeight(enabled: renderBottomBar);

    return SheetContent(
      bottomBar: renderBottomBar
          ? ColoredBox(
              key: bottomBarKey,
              color: context.theme.appColors.onPrimaryAccent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HorizontalSeparator(),
                  SizedBox(height: 16.0.s),
                  ScreenSideOffset.small(
                    child: continueButton!,
                  ),
                  SizedBox(
                    height: 16.0.s + MediaQuery.paddingOf(context).bottom,
                  ),
                ],
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: appBar ?? NavigationAppBar.modal(),
          ),
          SliverToBoxAdapter(
            child: AuthHeader(
              title: title,
              description: description,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 26.0.s),
          ),
          CollapsingAppBar(
            topOffset: 8.0.s,
            height: SearchInput.height,
            child: ScreenSideOffset.small(
              child: SearchInput(
                onTextChanged: (String value) => searchQuery.value = value,
              ),
            ),
          ),
          SliverList.separated(
            itemCount: filteredLanguages.length,
            separatorBuilder: (BuildContext _, int __) => SizedBox(height: 12.0.s),
            itemBuilder: (BuildContext context, int index) {
              final language = filteredLanguages[index];
              return LanguageListItem(
                language: language,
                isSelected: selectedLanguages.contains(language.isoCode),
                onTap: () => toggleLanguageSelection(language.isoCode),
              );
            },
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              bottom: 16.0.s +
                  (renderBottomBar ? bottomBarHeight : MediaQuery.paddingOf(context).bottom),
            ),
          ),
        ],
      ),
    );
  }
}
