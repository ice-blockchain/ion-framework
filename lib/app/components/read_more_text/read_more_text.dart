// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/theme_data.dart';

class ReadMoreText extends HookWidget {
  const ReadMoreText(
    this.text, {
    super.key,
    this.maxLines = 3,
  });

  final int maxLines;
  final String text;

  static String get ellipsis => '\u2026';

  static String get lineSeparator => '\u2028';

  @override
  Widget build(BuildContext context) {
    final showMore = useState(true);
    final defaultTextStyle = DefaultTextStyle.of(context);

    final textAlign = defaultTextStyle.textAlign ?? TextAlign.start;
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);

    final TapGestureRecognizer gestureRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          showMore.value = !showMore.value;
        },
      <Object?>[],
    );

    final link = TextSpan(
      text: showMore.value ? context.i18n.common_show_more : context.i18n.common_show_less,
      recognizer: gestureRecognizer,
      style:
          context.theme.appTextThemes.body2.copyWith(color: context.theme.appColors.primaryAccent),
    );

    final delimiter = TextSpan(
      text: showMore.value ? '$ellipsis ' : ' ',
      recognizer: gestureRecognizer,
    );

    final Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(
          constraints.hasBoundedWidth,
          'ReadMoreText must have bounded width',
        );
        final maxWidth = constraints.maxWidth;

        // Create a TextSpan with data
        final text = TextSpan(text: this.text);

        // Layout and measure link
        final textPainter = TextPainter(
          text: link,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: maxLines,
          locale: locale,
        )..layout(maxWidth: maxWidth);

        final linkSize = textPainter.size;

        // Layout and measure delimiter
        textPainter
          ..text = delimiter
          ..layout(maxWidth: maxWidth);

        final delimiterSize = textPainter.size;

        // Layout and measure text
        textPainter
          ..text = text
          ..layout(minWidth: constraints.minWidth, maxWidth: maxWidth);

        final textSize = textPainter.size;

        // Get the endIndex of data
        var linkLongerThanLine = false;
        int endIndex;

        if (linkSize.width < maxWidth) {
          final readMoreSize = linkSize.width + delimiterSize.width;
          final pos = textPainter.getPositionForOffset(
            Offset(
              textDirection == TextDirection.rtl ? readMoreSize : textSize.width - readMoreSize,
              textSize.height,
            ),
          );
          endIndex = textPainter.getOffsetBefore(pos.offset) ?? 0;
        } else {
          final pos = textPainter.getPositionForOffset(
            textDirection == TextDirection.rtl
                ? textSize.bottomRight(Offset.zero)
                : textSize.bottomLeft(Offset.zero),
          );
          endIndex = pos.offset;
          linkLongerThanLine = true;
        }

        late final TextSpan textSpan;

        late final String textData;

        if (textPainter.didExceedMaxLines) {
          textData = showMore.value
              ? this.text.substring(0, endIndex) + (linkLongerThanLine ? lineSeparator : '')
              : this.text;
          textSpan = TextSpan(
            text: textData,
            children: <TextSpan>[delimiter, link],
            style: context.theme.appTextThemes.body2
                .copyWith(color: context.theme.appColors.primaryText),
          );
        } else {
          textData = this.text;
          textSpan = TextSpan(
            text: textData,
          );
        }
        textPainter.dispose();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text.rich(
            key: ValueKey<String>(textData),
            textSpan,
            textAlign: textAlign,
            textDirection: textDirection,
            softWrap: true,
            overflow: TextOverflow.clip,
            textScaler: textScaler,
          ),
        );
      },
    );
    return result;
  }
}
