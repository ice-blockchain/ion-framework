// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/empty_list/empty_list.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/dapps/providers/dapps_provider.r.dart';
import 'package:ion/app/features/dapps/views/pages/dapps_list/dapps_list_item.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/generated/assets.gen.dart';

class DAppsList extends HookConsumerWidget {
  const DAppsList({required this.title, this.isSearchVisible = true, super.key});

  final String title;
  final bool isSearchVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = useState('');
    final apps = ref.watch(dappsDataProvider).valueOrNull ?? [];

    final searchLower = searchText.value.toLowerCase().trim();
    final filteredApps = searchLower.isEmpty
        ? apps
        : apps.where((app) => app.title.toLowerCase().contains(searchLower)).toList();

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(title),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ScreenSideOffset.small(
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: 12.0.s),
                child: Column(
                  children: [
                    if (isSearchVisible)
                      SearchInput(
                        restorationId: 'dapps_list_search_input',
                        onTextChanged: (String value) => searchText.value = value,
                      ),
                    Expanded(
                      child: apps.isEmpty
                          ? EmptyList(
                              asset: Assets.svg.walletIconWalletEmptyfavourites,
                              title: context.i18n.dapps_favourites_empty_title,
                            )
                          : filteredApps.isEmpty
                              ? NothingIsFound(
                                  title: context.i18n.search_nothing_found,
                                )
                              : ListView.builder(
                                  restorationId: 'dapps_list_scroll',
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10.0.s,
                                  ),
                                  itemCount: filteredApps.length,
                                  itemBuilder: (_, int index) =>
                                      DAppsListItem(app: filteredApps[index]),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
