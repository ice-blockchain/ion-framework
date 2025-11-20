// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/views/components/remove_from_search_history_button/remove_from_search_history_button.dart';

class SearchHistoryQueryListItem extends ConsumerWidget {
  const SearchHistoryQueryListItem({
    required this.query,
    required this.onTap,
    this.onDelete,
    super.key,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 8.0.s,
          horizontal: ScreenSideOffset.defaultSmallMargin,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                query,
                style: context.theme.appTextThemes.body2.copyWith(
                  color: context.theme.appColors.primaryText,
                ),
              ),
            ),
            if (onDelete != null)
              RemoveFromSearchHistoryButton(
                onDelete: onDelete!,
                style: RemoveFromSearchHistoryButtonStyle.inline,
              ),
          ],
        ),
      ),
    );
  }
}
