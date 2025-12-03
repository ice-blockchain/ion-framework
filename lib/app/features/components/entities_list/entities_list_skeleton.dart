// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/features/feed/views/components/post/post_skeleton.dart';

class EntitiesListSkeleton extends StatelessWidget {
  const EntitiesListSkeleton({
    super.key,
  });

  static const int numberOfItems = 4;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Skeleton(
        child: SeparatedColumn(
          separator: const SectionSeparator(),
          children: List.generate(
            numberOfItems,
            (_) => ScreenSideOffset.small(child: const PostSkeleton()),
          ).toList(),
        ),
      ),
    );
  }
}
