// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/generated/assets.gen.dart';

// Inline mention widget for the editor (badge-style with market cap and close).
class MentionInlineWidget extends HookWidget {
  const MentionInlineWidget({
    required this.username,
    required this.marketCap,
    this.onClose,
    this.onTap,
    super.key,
  });

  final String username;
  final double marketCap;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Calculate maximum safe height to avoid pushing line height
    // This is slightly smaller than line height to account for measurement differences
    final maxSafeHeight = useMemoized(() => calculateMaxSafeWidgetHeight(context), []);

    final widget = Stack(
      clipBehavior: Clip.none,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxSafeHeight,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsetsDirectional.fromSTEB(3.0.s, 2.0.s, 3.0.s, 1.0.s),
              decoration: BoxDecoration(
                color: context.theme.appColors.primaryBackground,
                borderRadius: BorderRadius.circular(8.0.s),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$mentionPrefix$username',
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.darkBlue,
                      height: 1,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                    strutStyle: const StrutStyle(forceStrutHeight: true),
                    textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
                  ),
                  SizedBox(width: 4.0.s),
                  Container(
                    padding: EdgeInsetsDirectional.fromSTEB(3.0.s, 0.5.s, 8.0.s, 1.0.s),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.0.s),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Assets.svg.iconMemeMarketcap.icon(
                          size: 12.0.s,
                          color: context.theme.appColors.onTertiaryBackground,
                        ),
                        SizedBox(width: 2.0.s),
                        Text(
                          '\$${MarketDataFormatter.formatCompactNumber(marketCap)}',
                          style: context.theme.appTextThemes.caption2.copyWith(
                            color: context.theme.appColors.onTertiaryBackground,
                            height: 1,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                          strutStyle: const StrutStyle(forceStrutHeight: true),
                          textHeightBehavior:
                              const TextHeightBehavior(applyHeightToFirstAscent: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onClose != null)
          PositionedDirectional(
            top: -10.0.s,
            end: -10.0.s,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onClose,
              child: Container(
                width: 20.0.s, // larger hit target
                height: 20.0.s,
                alignment: Alignment.center,
                child: Container(
                  width: 14.0.s,
                  height: 14.0.s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(12.0.s),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.4.s,
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 9.0.s,
                    color: context.theme.appColors.secondaryText,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }

    return widget;
  }
}
