// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/views/components/search_history/search_history_header.dart';
import 'package:ion/app/features/search/views/components/search_history/search_history_query_list_item.dart';

class SearchHistory extends StatelessWidget {
  const SearchHistory({
    required this.itemCount,
    required this.itemBuilder,
    required this.queries,
    required this.onSelectQuery,
    required this.onClearHistory,
    this.onDeleteQuery,
    super.key,
  });

  final int itemCount;
  final List<String> queries;
  final void Function(String query) onSelectQuery;
  final VoidCallback onClearHistory;
  final NullableIndexedWidgetBuilder itemBuilder;
  final void Function(String query)? onDeleteQuery;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          SizedBox(height: 20.0.s),
          SearchHistoryHeader(onClearHistory: onClearHistory),
          if (itemCount != 0)
            Padding(
              padding: EdgeInsetsDirectional.only(top: 16.0.s),
              child: SizedBox(
                height: 105.0.s,
                child: ListView.separated(
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (context, index) => SizedBox(width: 12.0.s),
                  padding: EdgeInsets.symmetric(horizontal: ScreenSideOffset.defaultSmallMargin),
                ),
              ),
            ),
          if (queries.isNotEmpty)
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.0.s),
                itemCount: queries.length,
                itemBuilder: (context, index) {
                  final query = queries[index];
                  return SearchHistoryQueryListItem(
                    query: queries[index],
                    onTap: () {
                      onSelectQuery(query);
                    },
                    onDelete: onDeleteQuery != null ? () => onDeleteQuery!(query) : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
