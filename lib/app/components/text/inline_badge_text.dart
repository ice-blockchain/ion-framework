// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class InlineBadgeText extends StatelessWidget {
  const InlineBadgeText({
    required this.titleSpan,
    this.badges = const <Widget>[],
    this.gap = 2.0,
    this.style,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textAlign,
    this.strutStyle,
    this.trailingGap,
    super.key,
  });

  final InlineSpan titleSpan;
  final List<Widget> badges;
  final double gap;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextAlign? textAlign;
  final StrutStyle? strutStyle;
  final double? trailingGap;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[titleSpan];
    for (final badge in badges) {
      spans
        ..add(WidgetSpan(child: SizedBox(width: gap)))
        ..add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: badge,
          ),
        );
    }
    if (trailingGap != null && trailingGap! > 0) {
      spans.add(WidgetSpan(child: SizedBox(width: trailingGap)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textAlign: textAlign,
      strutStyle: strutStyle,
    );
  }
}
