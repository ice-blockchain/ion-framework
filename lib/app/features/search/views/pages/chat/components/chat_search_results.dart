// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/search/views/pages/chat/components/chat_search_results_list_item.dart';

class ChatSearchResults extends ConsumerWidget {
  const ChatSearchResults({
    required this.searchResults,
    this.showLastMessage = true,
    super.key,
  });

  final bool showLastMessage;
  final List<ChatSearchResultItem> searchResults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: searchResults.length,
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      itemBuilder: (context, index) {
        return Column(
          children: [
            ChatSearchResultListItem(
              showLastMessage: showLastMessage,
              item: searchResults[index],
            ),
            if (index < searchResults.length - 1)
              const HorizontalSeparator()
            else
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: 12.s),
                child: const HorizontalSeparator(),
              ),
          ],
        );
      },
    );
  }
}
