// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';

/// Inline mention widget for the editor (badge-style with market cap and close).
class MentionInlineWidget extends StatelessWidget {
  const MentionInlineWidget({
    super.key,
    required this.username,
    required this.marketCap,
    this.onClose,
  });

  final String username;
  final double marketCap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bg = context.theme.appColors.primaryBackground;
    final capTextColor = context.theme.appColors.onTertiaryBackground;
    final usernameColor = const Color(0xFF1D46EB); // Dark Blue from Figma

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 20.0.s,
          padding: EdgeInsets.symmetric(horizontal: 4.0.s, vertical: 2.0.s),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10.0.s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$mentionPrefix$username',
                style: TextStyle(
                  fontFamily: 'Noto Sans',
                  fontSize: 13.0.s,
                  fontWeight: FontWeight.w400,
                  color: usernameColor,
                  height: 1.0,
                ),
              ),
              if (marketCap > 0) ...[
                SizedBox(width: 4.0.s),
                Container(
                  padding: EdgeInsetsDirectional.fromSTEB(3.0.s, 2.0.s, 6.0.s, 2.0.s),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8.0.s),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.savings_outlined, // money bag approximation
                        size: 10.0.s,
                        color: capTextColor,
                      ),
                      SizedBox(width: 2.0.s),
                      Text(
                        '\$${MarketDataFormatter.formatCompactNumber(marketCap)}',
                        style: TextStyle(
                          fontFamily: 'Noto Sans',
                          fontSize: 13.0.s,
                          fontWeight: FontWeight.w400,
                          color: capTextColor,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: -6.0.s,
          right: -10.0.s,
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 20.0.s,
              height: 20.0.s,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0.s),
              ),
              child: Icon(
                Icons.close,
                size: 12.0.s,
                color: capTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
