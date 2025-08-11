// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/shadow/svg_shadow.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/counters/like_reaction_provider.r.dart';
import 'package:ion/app/features/feed/providers/counters/likes_count_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/features/likes/post_like_provider.r.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class TrendingVideoLikesButton extends ConsumerWidget {
  const TrendingVideoLikesButton({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesCount = ref.watch(likesCountProvider(eventReference));
    final isLiked = ref.watch(isLikedProvider(eventReference));
    final appColors = context.theme.appColors;
    final color = isLiked ? appColors.attentionRed : appColors.onPrimaryAccent;

    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12.0.s),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        ref.read(toggleLikeNotifierProvider.notifier).toggle(eventReference);
      },
      child: Row(
        children: [
          SvgShadow(
            child: (isLiked ? Assets.svg.iconVideoLikeOn : Assets.svg.iconVideoLikeOff).icon(
              size: 14.0.s,
              color: color,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(start: 2.0.s),
            child: Text(
              formatDoubleCompact(likesCount),
              style: context.theme.appTextThemes.caption3.copyWith(
                color: color,
                shadows: [
                  BoxShadow(
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                    color: Colors.black.withValues(alpha: 0.40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
