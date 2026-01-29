// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/dapps/model/dapp_data.f.dart';
import 'package:ion/app/features/search/providers/dapps_search_history_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class DAppsSearchResultsListItem extends ConsumerWidget {
  const DAppsSearchResultsListItem({required this.app, super.key});

  static double get itemVerticalOffset => 8.0.s;

  final DAppData app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemVerticalOffset),
      child: ScreenSideOffset.small(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(dAppsSearchHistoryProvider.notifier).addDAppIdToTheHistory(app.identifier);
            DAppDetailsRoute(dappId: app.identifier).push<void>(context);
          },
          child: ListItem.dapp(
            titleSpan: TextSpan(text: app.title),
            subtitle: Text(app.description ?? ''),
            profilePictureWidget: Image.asset(
              app.iconImage,
              width: 48.0.s,
              cacheWidth: (MediaQuery.devicePixelRatioOf(context) * 48.0.s).toInt(),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
