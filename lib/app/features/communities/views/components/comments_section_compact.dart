// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class CommentsSectionCompact extends StatelessWidget {
  const CommentsSectionCompact({
    required this.commentCount,
    this.onTapComposer,
    this.avatar,
    super.key,
  });

  final int commentCount;
  final VoidCallback? onTapComposer;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    return ColoredBox(
      color: colors.secondaryBackground,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Assets.svg.iconBlockComment.icon(size: 18.0.s, color: colors.onTertiaryBackground),
                SizedBox(width: 6.0.s),
                Text(
                  '${i18n.common_comments} ($commentCount)',
                  style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
                ),
              ],
            ),
            SizedBox(height: 12.0.s),
            // Composer teaser
            Row(
              children: [
                avatar ?? _AvatarPlaceholder(),
                SizedBox(width: 6.0.s),
                Expanded(
                  child: GestureDetector(
                    onTap: onTapComposer,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 36.0.s,
                      decoration: BoxDecoration(
                        color: colors.onSecondaryBackground,
                        borderRadius: BorderRadius.circular(14.0.s),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        i18n.feed_write_comment,
                        style: texts.subtitle3.copyWith(color: colors.quaternaryText),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return Container(
      width: 36.0.s,
      height: 36.0.s,
      decoration: BoxDecoration(
        color: colors.onTertiaryFill,
        borderRadius: BorderRadius.circular(12.0.s),
      ),
    );
  }
}
