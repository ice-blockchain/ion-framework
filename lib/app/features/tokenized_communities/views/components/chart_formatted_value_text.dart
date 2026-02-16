// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/price_label_formatter.dart';

List<TextSpan> buildFormattedValueTextSpans({
  required PriceLabelParts parts,
  required TextStyle style,
  TextStyle? subscriptStyle,
}) {
  if (parts.fullText != null) {
    return [TextSpan(text: parts.fullText, style: style)];
  }

  return [
    TextSpan(text: parts.prefix ?? '', style: style),
    if (parts.subscript != null) TextSpan(text: parts.subscript, style: subscriptStyle ?? style),
    TextSpan(text: parts.trailing ?? '', style: style),
  ];
}

class ChartFormattedValueText extends StatelessWidget {
  const ChartFormattedValueText({
    required this.parts,
    required this.style,
    this.subscriptStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final PriceLabelParts parts;
  final TextStyle style;
  final TextStyle? subscriptStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static final _subscriptOffset = Offset(0, 2.0.s);
  static const _subscriptScale = 0.8;

  bool get _hasRichParts => parts.fullText == null;

  String get _plainText =>
      parts.fullText ?? '${parts.prefix ?? ''}${parts.subscript ?? ''}${parts.trailing ?? ''}';

  @override
  Widget build(BuildContext context) {
    if (!_hasRichParts) {
      return Text(
        _plainText,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: parts.prefix ?? ''),
          if (parts.subscript != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Transform.translate(
                offset: _subscriptOffset,
                child: Text(
                  parts.subscript!,
                  style: subscriptStyle ??
                      style.copyWith(
                        fontSize: style.fontSize != null ? style.fontSize! * _subscriptScale : null,
                      ),
                ),
              ),
            ),
          TextSpan(text: parts.trailing ?? ''),
        ],
      ),
    );
  }
}
