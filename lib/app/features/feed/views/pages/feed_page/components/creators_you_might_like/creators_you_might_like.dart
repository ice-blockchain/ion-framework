// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/section_header/section_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/feed_recommended_creators_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/creators_you_might_like/components/creator_card.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorsYouMightLike extends ConsumerWidget {
  const CreatorsYouMightLike({super.key});

  static double get _listHeight => 120.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorsAsync = ref.watch(feedRecommendedCreatorsProvider);
    final creators = creatorsAsync.valueOrNull?.items ?? const <String>[];
    if (creators.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: context.i18n.feed_creators_you_might_like,
          leadingIcon: Assets.svg.iconInviteCreator2.icon(size: 24.0.s),
          trailingIconSize: 20.0.s,
        ),
        SizedBox(
          height: _listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSideOffset.defaultSmallMargin,
            ),
            itemCount: creators.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.0.s),
            itemBuilder: (context, index) {
              return CreatorCard(masterPubkey: creators[index]);
            },
          ),
        ),
        SizedBox(height: 12.0.s),
      ],
    );
  }
}
