// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/generated/assets.gen.dart';

/// Inline mention widget for the editor (badge-style with market cap and close).
class MentionInlineWidget extends StatelessWidget {
  const MentionInlineWidget({
    required this.username,
    required this.marketCap,
    this.onClose,
    super.key,
  });

  final String username;
  final double marketCap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bg = context.theme.appColors.primaryBackground;
    final capTextColor = context.theme.appColors.onTertiaryBackground;
    final usernameColor = context.theme.appColors.darkBlue;
    final textStyle = context.theme.appTextThemes.body2;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.0.s, vertical: 1.0.s),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.0.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$mentionPrefix$username',
            style: textStyle.copyWith(
              color: usernameColor,
              height: 1,
            ),
          ),
          SizedBox(width: 4.0.s),
          Container(
            padding: EdgeInsetsDirectional.fromSTEB(3.0.s, 0.5.s, 8.0.s, 1.0.s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0.s),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.svg.iconMemeMarketcap.icon(
                  size: 12.0.s,
                  color: capTextColor,
                ),
                SizedBox(width: 2.0.s),
                Text(
                  '\$${MarketDataFormatter.formatCompactNumber(marketCap)}',
                  style: context.theme.appTextThemes.caption2.copyWith(
                    color: capTextColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
