// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/dapps/model/dapp_data.f.dart';
import 'package:ion/app/features/search/views/pages/dapps_simple_search_page/components/search_results/dapps_search_results_list_item.dart';

class DAppsSearchResults extends StatelessWidget {
  const DAppsSearchResults({
    required this.apps,
    super.key,
  });

  final List<DAppData> apps;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        restorationId: 'search_dapps_results_scroll',
        padding: EdgeInsets.symmetric(
          vertical: 10.0.s,
        ),
        itemCount: apps.length,
        itemBuilder: (BuildContext _, int index) => DAppsSearchResultsListItem(app: apps[index]),
      ),
    );
  }
}
