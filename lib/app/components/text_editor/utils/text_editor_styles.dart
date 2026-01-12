// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/extensions/extensions.dart';

DefaultStyles textEditorStyles(BuildContext context, {Color? color}) {
  final textColor = color ?? context.theme.appColors.postContent;
  return DefaultStyles(
    paragraph: DefaultTextBlockStyle(
      context.theme.appTextThemes.body2.copyWith(
        color: textColor,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      HorizontalSpacing.zero,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    bold: context.theme.appTextThemes.body2.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
    italic: context.theme.appTextThemes.body2.copyWith(
      fontStyle: FontStyle.italic,
      color: textColor,
    ),
    placeHolder: DefaultTextBlockStyle(
      context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.tertiaryText,
      ),
      HorizontalSpacing.zero,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    lists: DefaultListBlockStyle(
      context.theme.appTextThemes.body2.copyWith(
        color: textColor,
        fontSize: context.theme.appTextThemes.body2.fontSize,
      ),
      HorizontalSpacing.zero,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
      null,
    ),
    quote: DefaultTextBlockStyle(
      context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.primaryText,
        fontStyle: FontStyle.italic,
      ),
      HorizontalSpacing.zero,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: context.theme.appColors.primaryAccent,
            width: 2.0.s,
          ),
        ),
      ),
    ),
  );
}

DefaultStyles textEditorStylesPlainInline(BuildContext context, {Color? color}) {
  final base = textEditorStyles(context, color: color);

  final paragraphStyle = base.paragraph?.style ??
      context.theme.appTextThemes.body2.copyWith(
        color: color ?? context.theme.appColors.postContent,
      );
  return DefaultStyles(
    paragraph: base.paragraph,
    placeHolder: base.placeHolder,
    lists: base.lists,
    quote: base.quote,
    // NOTE: ignore inline bold and italic styles
    bold: paragraphStyle,
    italic: paragraphStyle,
  );
}

TextStyle customTextStyleBuilder(
  Attribute<dynamic> attribute,
  BuildContext context, {
  Color? tagsColor,
}) {
  if (attribute.key == HashtagAttribute.attributeKey ||
      attribute.key == CashtagAttribute.attributeKey ||
      attribute.key == MentionAttribute.attributeKey) {
    return TextStyle(
      color: tagsColor ?? context.theme.appColors.primaryAccent,
      decoration: TextDecoration.none,
    );
  } else if (attribute.key == Attribute.link.key) {
    return TextStyle(
      decoration: TextDecoration.underline,
      color: context.theme.appColors.primaryAccent,
    );
  } else if (attribute.key == Attribute.codeBlock.key) {
    return const TextStyle();
  }

  return const TextStyle();
}

// Calculates the exact line height in pixels for the text editor.
// Uses TextPainter to measure the actual rendered line height,
// accounting for font size, line height multiplier, and TextScaler.
double calculateTextEditorLineHeight(BuildContext context) {
  final textStyle = context.theme.appTextThemes.body2.copyWith(
    leadingDistribution: TextLeadingDistribution.even,
  );

  final textScaler = MediaQuery.textScalerOf(context);

  final textPainter = TextPainter(
    text: TextSpan(text: 'A', style: textStyle), // Single character to measure
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();

  final lineMetrics = textPainter.computeLineMetrics();
  final lineHeight = lineMetrics.isNotEmpty ? lineMetrics.first.height : textPainter.height;
  textPainter.dispose();

  return lineHeight;
}

// Calculates the maximum safe height for an inline widget to avoid pushing line height.
// WidgetSpan measures the widget during layout, and even with constraints, the measured height
// can cause line height expansion. Returns 95% of line height as an empirically safe value.
double calculateMaxSafeWidgetHeight(BuildContext context) {
  final lineHeight = calculateTextEditorLineHeight(context);
  final safeHeight = lineHeight * 0.95;

  return safeHeight;
}
