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
