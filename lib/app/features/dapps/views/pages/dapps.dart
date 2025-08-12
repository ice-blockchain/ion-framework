// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/dapps/providers/dapps_provider.r.dart';
import 'package:ion/app/features/dapps/views/categories/apps/apps.dart';
import 'package:ion/app/features/dapps/views/categories/featured.dart';
import 'package:ion/app/features/dapps/views/components/categories/categories.dart';
import 'package:ion/app/features/dapps/views/components/dapps_header/dapps_header.dart';
import 'package:ion/app/features/dapps/views/components/favourites/favourites.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class DAppsPage extends HookConsumerWidget {
  const DAppsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final apps = ref.watch(dappsDataProvider).valueOrNull ?? [];

    useScrollTopOnTabPress(context, scrollController: scrollController);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(DAppsHeader.height),
        child: const SafeArea(child: DAppsHeader()),
      ),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const Featured(),
                Padding(
                  padding: EdgeInsetsDirectional.only(top: 20.0.s, bottom: 7.0.s),
                  child: Container(
                    height: 10.0.s,
                    color: context.theme.appColors.primaryBackground,
                  ),
                ),
                const Categories(),
                Apps(
                  title: context.i18n.dapps_section_title_highest_ranked,
                  items: apps,
                  onPress: () {
                    DAppsListRoute(
                      title: context.i18n.dapps_section_title_highest_ranked,
                      isSearchVisible: false,
                    ).push<void>(context);
                  },
                ),
                Apps(
                  title: context.i18n.dapps_section_title_recently_added,
                  items: apps,
                  topOffset: 8.0.s,
                  onPress: () {
                    DAppsListRoute(
                      title: context.i18n.dapps_section_title_recently_added,
                    ).push<void>(context);
                  },
                ),
                Favourites(
                  onPress: () {
                    DAppsListRoute(
                      title: context.i18n.dapps_section_title_favourites,
                    ).push<void>(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
