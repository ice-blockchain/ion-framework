// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/likes_counter_button.dart';
import 'package:ion/app/components/counter_items_footer/post_token.dart';
import 'package:ion/app/components/counter_items_footer/replies_counter_button.dart';
import 'package:ion/app/components/counter_items_footer/reposts_counter_button.dart';
import 'package:ion/app/components/counter_items_footer/share_button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/components/bookmark_button/bookmark_button.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

class CounterItemsFooter extends HookConsumerWidget {
  const CounterItemsFooter({
    required this.eventReference,
    this.itemPadding,
    this.sidePadding,
    this.color,
    this.onReplyTap,
    super.key,
  });

  final EventReference eventReference;
  final EdgeInsetsDirectional? itemPadding;
  final double? sidePadding;
  final Color? color;
  final VoidCallback? onReplyTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconPadding = EdgeInsetsDirectional.symmetric(vertical: 6.0.s);
    final sidePadding = this.sidePadding ?? ScreenSideOffset.defaultSmallMargin;
    final itemPadding =
        this.itemPadding ?? EdgeInsetsDirectional.only(top: 10.0.s, bottom: 12.0.s) + iconPadding;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Center(
          child: RepliesCounterButton(
            eventReference: eventReference,
            padding: itemPadding + EdgeInsetsDirectional.symmetric(horizontal: sidePadding),
            color: color,
            onTap: onReplyTap,
          ),
        ),
        Center(
          child: RepostsCounterButton(
            eventReference: eventReference,
            padding: itemPadding,
            color: color,
          ),
        ),
        Center(
          child: LikesCounterButton(
            eventReference: eventReference,
            padding: itemPadding,
            color: color,
          ),
        ),
        Center(
          child: PostToken(
            eventReference: eventReference,
            padding: itemPadding,
          ),
        ),
        Center(
          child: Row(
            children: [
              BookmarkButton(
                eventReference: eventReference,
                size: 16.0.s,
                padding: itemPadding + EdgeInsetsDirectional.only(end: 8.0.s, start: 14.0.s),
                color: color ?? context.theme.appColors.onTertiaryBackground,
              ),
              ShareButton(
                eventReference: eventReference,
                padding: itemPadding + EdgeInsetsDirectional.only(end: sidePadding, start: 8.0.s),
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
