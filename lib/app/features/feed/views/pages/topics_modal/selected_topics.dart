// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/feed/views/pages/topics_modal/components/category_header.dart';
import 'package:ion/app/features/feed/views/pages/topics_modal/components/selected_topic_pill.dart';

class SelectedTopics extends HookConsumerWidget {
  const SelectedTopics({
    required this.feedType,
    super.key,
  });

  final FeedType feedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableInterests = ref.watch(feedUserInterestsProvider(feedType)).valueOrNull;
    if (availableInterests == null) {
      return const SizedBox.shrink();
    }

    final availableSubcategories = availableInterests.subcategories;
    final selected = ref.watch(
      selectedInterestsNotifierProvider.select(
        (interests) => interests.where(availableSubcategories.containsKey).toSet(),
      ),
    );
    final initiallySelected = useRef(selected);
    if (initiallySelected.value.isEmpty || selected.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6.0.s,
      children: [
        CategoryHeader(
          categoryName: context.i18n.common_selected,
        ),
        SizedBox(
          height: 34.s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selected.length,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ScreenSideOffset.defaultSmallMargin,
            ),
            separatorBuilder: (_, __) => SizedBox(width: 8.s),
            itemBuilder: (context, index) {
              final subcategoryKey = selected.elementAt(index);
              return SelectedTopicPill(
                key: ValueKey(subcategoryKey),
                categoryName: availableSubcategories[subcategoryKey]?.display ?? subcategoryKey,
                onRemove: () =>
                    ref.read(selectedInterestsNotifierProvider.notifier).toggleSubcategory(
                          feedType: feedType,
                          subcategoryKey: subcategoryKey,
                        ),
              );
            },
          ),
        ),
      ],
    );
  }
}
