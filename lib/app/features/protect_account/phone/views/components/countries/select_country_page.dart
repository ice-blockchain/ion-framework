// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/protect_account/phone/provider/country_provider.r.dart';
import 'package:ion/app/features/protect_account/phone/views/components/countries/countries.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/show_close_button_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SelectCountryPage extends HookConsumerWidget {
  const SelectCountryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = useState('');
    final filteredCountriesAsync = ref.watch(countryFilterProvider(searchText.value));

    return SheetContent(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: Column(
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.select_countries_nav_title),
            showCloseButton: ref.watch(showCloseButtonProvider),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                CountrySearchHeader(
                  isLoading: filteredCountriesAsync.isLoading,
                  onTextChanged: (value) => searchText.value = value,
                  onCancelSearch: () => searchText.value = '',
                ),
                filteredCountriesAsync.maybeWhen(
                  data: (filteredCountries) => SliverList.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (BuildContext context, int index) {
                      final country = filteredCountries[index];
                      return CountryListItem(
                        key: ValueKey(country),
                        country: country,
                        onTap: () => context.pop(country),
                      );
                    },
                  ),
                  orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverPadding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: 16.0.s + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
