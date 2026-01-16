// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
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
    final textStyle = context.theme.appTextThemes.caption2.copyWith(
      height: 1,
      leadingDistribution: TextLeadingDistribution.even,
    );

    final textRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 2.0.s),
        Text(
          '$mentionPrefix$username',
          style: textStyle.copyWith(
            color: context.theme.appColors.darkBlue,
          ),
          strutStyle: const StrutStyle(forceStrutHeight: true),
          textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
        ),
        SizedBox(width: 4.0.s),
        MentionInlineRenderObjectWidget(
          backgroundColor: context.theme.appColors.secondaryBackground,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(6.0.s),
          child: Row(
            children: [
              SizedBox(width: 2.0.s),
              Assets.svg.iconMemeMarketcap.icon(
                size: 12.0.s,
                color: context.theme.appColors.onTertiaryBackground,
              ),
              SizedBox(width: 2.0.s),
              Text(
                '\$${MarketDataFormatter.formatCompactNumber(marketCap)}',
                style: textStyle.copyWith(
                  color: context.theme.appColors.onTertiaryBackground,
                ),
                strutStyle: const StrutStyle(forceStrutHeight: true),
                textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
              ),
              SizedBox(width: 2.0.s),
              if (onClose != null) SizedBox(width: 8.0.s),
            ],
          ),
        ),
      ],
    );

    final widget = Padding(
      padding: (onClose != null) ? EdgeInsetsDirectional.only(end: 4.0.s) : EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MentionInlineRenderObjectWidget(
            backgroundColor: context.theme.appColors.primaryBackground,
            padding: EdgeInsetsDirectional.all(2.0.s),
            borderRadius: BorderRadius.circular(8.0.s),
            child: textRow,
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
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12.0.s,
                      color: context.theme.appColors.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Only wrap with GestureDetector for navigation when no close button (view mode).
    // In edit mode (when onClose is present), the close button needs to be reachable.
    if (onTap != null && onClose == null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }

    return widget;
  }
}

class MentionInlineRenderObjectWidget extends SingleChildRenderObjectWidget {
  const MentionInlineRenderObjectWidget({
    required this.backgroundColor,
    required this.padding,
    required this.borderRadius,
    super.child,
    super.key,
  });

  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  RenderMentionInline createRenderObject(BuildContext context) {
    return RenderMentionInline(
      backgroundColor: backgroundColor,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMentionInline renderObject,
  ) {
    renderObject
      ..backgroundColor = backgroundColor
      ..padding = padding
      ..borderRadius = borderRadius;
  }
}

class RenderMentionInline extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderMentionInline({
    required this.backgroundColor,
    required this.padding,
    required this.borderRadius,
    RenderBox? child,
  }) {
    this.child = child;
  }

  Color backgroundColor;
  EdgeInsetsGeometry padding;
  BorderRadius borderRadius;

  @override
  void performLayout() {
    if (child == null) {
      size = Size.zero;
      return;
    }

    child!.layout(constraints, parentUsesSize: true);
    size = child!.size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final resolvedPadding = padding.resolve(TextDirection.ltr);
    final backgroundWidth = child!.size.width + resolvedPadding.horizontal;
    final backgroundHeight = child!.size.height + resolvedPadding.vertical;

    context.canvas.save();
    context.canvas.translate(
      offset.dx - resolvedPadding.left,
      offset.dy - resolvedPadding.top,
    );

    final backgroundRect = Rect.fromLTWH(
      0,
      0,
      backgroundWidth,
      backgroundHeight,
    );

    final backgroundPaint = Paint()..color = backgroundColor;
    final roundedRect = RRect.fromRectAndRadius(
      backgroundRect,
      Radius.circular(borderRadius.topLeft.x),
    );

    context.canvas.drawRRect(roundedRect, backgroundPaint);
    context.canvas.restore();

    context.paintChild(child!, offset);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return 0;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      return child!.hitTest(result, position: position);
    }
    return false;
  }
}
