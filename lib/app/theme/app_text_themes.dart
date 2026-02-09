// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/templates/template.f.dart';

class AppTextThemesExtension extends ThemeExtension<AppTextThemesExtension> {
  const AppTextThemesExtension({
    required this.headline1,
    required this.headline2,
    required this.title,
    required this.subtitle,
    required this.subtitle2,
    required this.subtitle3,
    required this.body,
    required this.body2,
    required this.caption,
    required this.caption2,
    required this.caption3,
    required this.caption4,
    required this.caption5,
    required this.caption6,
    required this.notificationCaption,
  });

  factory AppTextThemesExtension.fromTemplate(TemplateTextThemes textThemes) {
    final defaults = AppTextThemesExtension.defaultTextThemes();
    return AppTextThemesExtension(
      headline1:
          TemplateTextStyle.fromTemplate(textThemes.headline1, defaultStyle: defaults.headline1),
      headline2:
          TemplateTextStyle.fromTemplate(textThemes.headline2, defaultStyle: defaults.headline2),
      title: TemplateTextStyle.fromTemplate(textThemes.title, defaultStyle: defaults.title),
      subtitle:
          TemplateTextStyle.fromTemplate(textThemes.subtitle, defaultStyle: defaults.subtitle),
      subtitle2:
          TemplateTextStyle.fromTemplate(textThemes.subtitle2, defaultStyle: defaults.subtitle2),
      subtitle3:
          TemplateTextStyle.fromTemplate(textThemes.subtitle3, defaultStyle: defaults.subtitle3),
      body: TemplateTextStyle.fromTemplate(textThemes.body, defaultStyle: defaults.body),
      body2: TemplateTextStyle.fromTemplate(textThemes.body2, defaultStyle: defaults.body2),
      caption: TemplateTextStyle.fromTemplate(textThemes.caption, defaultStyle: defaults.caption),
      caption2:
          TemplateTextStyle.fromTemplate(textThemes.caption2, defaultStyle: defaults.caption2),
      caption3:
          TemplateTextStyle.fromTemplate(textThemes.caption3, defaultStyle: defaults.caption3),
      caption4:
          TemplateTextStyle.fromTemplate(textThemes.caption4, defaultStyle: defaults.caption4),
      caption5:
          TemplateTextStyle.fromTemplate(textThemes.caption5, defaultStyle: defaults.caption5),
      caption6:
          TemplateTextStyle.fromTemplate(textThemes.caption6, defaultStyle: defaults.caption6),
      notificationCaption: TemplateTextStyle.fromTemplate(
        textThemes.notificationCaption,
        defaultStyle: defaults.notificationCaption,
      ),
    );
  }

  factory AppTextThemesExtension.defaultTextThemes() {
    return const AppTextThemesExtension(
      headline1: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      headline2: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      title: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      subtitle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      subtitle2: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      subtitle3: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      body: TextStyle(fontSize: 13, height: 1.37, fontWeight: FontWeight.w600),
      body2: TextStyle(fontSize: 13, height: 1.37, fontWeight: FontWeight.w400),
      caption: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      caption2: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      caption3: TextStyle(fontSize: 11, height: 1.63, fontWeight: FontWeight.w400),
      caption4: TextStyle(fontSize: 11, height: 1.45, fontWeight: FontWeight.w600),
      caption5: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
      caption6: TextStyle(fontSize: 11, height: 1.6, fontWeight: FontWeight.w500),
      notificationCaption: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
    );
  }

  final TextStyle headline1;
  final TextStyle headline2;
  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle subtitle2;
  final TextStyle subtitle3;
  final TextStyle body;
  final TextStyle body2;
  final TextStyle caption;
  final TextStyle caption2;
  final TextStyle caption3;
  final TextStyle caption4;
  final TextStyle caption5;
  final TextStyle caption6;
  final TextStyle notificationCaption;

  @override
  ThemeExtension<AppTextThemesExtension> copyWith({
    TextStyle? headline1,
    TextStyle? headline2,
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? subtitle2,
    TextStyle? subtitle3,
    TextStyle? body,
    TextStyle? body2,
    TextStyle? caption,
    TextStyle? caption2,
    TextStyle? caption3,
    TextStyle? caption4,
    TextStyle? caption5,
    TextStyle? caption6,
    TextStyle? notificationCaption,
  }) {
    return AppTextThemesExtension(
      headline1: headline1 ?? this.headline1,
      headline2: headline2 ?? this.headline2,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      subtitle2: subtitle2 ?? this.subtitle2,
      subtitle3: subtitle3 ?? this.subtitle3,
      body: body ?? this.body,
      body2: body2 ?? this.body2,
      caption: caption ?? this.caption,
      caption2: caption2 ?? this.caption2,
      caption3: caption3 ?? this.caption3,
      caption4: caption4 ?? this.caption4,
      caption5: caption5 ?? this.caption5,
      caption6: caption6 ?? this.caption6,
      notificationCaption: notificationCaption ?? this.notificationCaption,
    );
  }

  @override
  ThemeExtension<AppTextThemesExtension> lerp(
    covariant ThemeExtension<AppTextThemesExtension>? other,
    double t,
  ) {
    if (other is! AppTextThemesExtension) {
      return this;
    }

    return AppTextThemesExtension(
      headline1: TextStyle.lerp(headline1, other.headline1, t)!,
      headline2: TextStyle.lerp(headline2, other.headline2, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t)!,
      subtitle2: TextStyle.lerp(subtitle2, other.subtitle2, t)!,
      subtitle3: TextStyle.lerp(subtitle3, other.subtitle3, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      body2: TextStyle.lerp(body2, other.body2, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      caption2: TextStyle.lerp(caption2, other.caption2, t)!,
      caption3: TextStyle.lerp(caption3, other.caption3, t)!,
      caption4: TextStyle.lerp(caption4, other.caption4, t)!,
      caption5: TextStyle.lerp(caption5, other.caption5, t)!,
      caption6: TextStyle.lerp(caption6, other.caption6, t)!,
      notificationCaption: TextStyle.lerp(notificationCaption, other.notificationCaption, t)!,
    );
  }
}

class TemplateTextStyle extends TextStyle {
  static TextStyle fromTemplate(TemplateTextTheme theme, {TextStyle? defaultStyle}) {
    return TextStyle(
      fontSize: theme.fontSize ?? defaultStyle?.fontSize,
      fontWeight: theme.fontWeight ?? defaultStyle?.fontWeight,
      height: theme.height ?? defaultStyle?.height,
      fontFamily: 'NotoSans',
      letterSpacing: 0,
    );
  }
}
