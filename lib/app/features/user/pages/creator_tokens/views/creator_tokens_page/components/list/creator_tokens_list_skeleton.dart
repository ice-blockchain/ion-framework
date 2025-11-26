// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/num.dart';

class CreatorTokensListSkeleton extends StatelessWidget {
  const CreatorTokensListSkeleton({super.key});

  static const int numberOfItems = 8;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        children: List.generate(
          numberOfItems,
          (_) => Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.s),
            child: ScreenSideOffset.small(
              child: const ListItemUserShape(),
            ),
          ),
        ),
      ),
    );
  }
}
