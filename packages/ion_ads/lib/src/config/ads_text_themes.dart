// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class AdsTextThemesExtension extends ThemeExtension<AdsTextThemesExtension> {
  const AdsTextThemesExtension({
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

  factory AdsTextThemesExtension.defaultTextThemes() {
    return const AdsTextThemesExtension(
      headline1: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      headline2: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      title: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      subtitle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      subtitle2: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      subtitle3: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      body: TextStyle(
        fontSize: 13,
        height: 1.37,
        fontWeight: FontWeight.w600,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      body2: TextStyle(
        fontSize: 13,
        height: 1.37,
        fontWeight: FontWeight.w400,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      caption: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      caption2: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      caption3: TextStyle(
        fontSize: 11,
        height: 1.63,
        fontWeight: FontWeight.w400,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      caption4: TextStyle(
        fontSize: 11,
        height: 1.45,
        fontWeight: FontWeight.w600,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      caption5: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      caption6: TextStyle(
        fontSize: 11,
        height: 1.6,
        fontWeight: FontWeight.w500,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
      notificationCaption: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        fontFamily: 'NotoSans',
        letterSpacing: 0,
      ),
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
  ThemeExtension<AdsTextThemesExtension> copyWith({
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
    return AdsTextThemesExtension(
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

  AdsTextThemesExtension apply({
    Color? color,
    Color? backgroundColor,
  }) {
    return AdsTextThemesExtension(
      headline1: headline1.apply(color: color, backgroundColor: backgroundColor),
      headline2: headline2.apply(color: color, backgroundColor: backgroundColor),
      title: title.apply(color: color, backgroundColor: backgroundColor),
      subtitle: subtitle.apply(color: color, backgroundColor: backgroundColor),
      subtitle2: subtitle2.apply(color: color, backgroundColor: backgroundColor),
      subtitle3: subtitle3.apply(color: color, backgroundColor: backgroundColor),
      body: body.apply(color: color, backgroundColor: backgroundColor),
      body2: body2.apply(color: color, backgroundColor: backgroundColor),
      caption: caption.apply(color: color, backgroundColor: backgroundColor),
      caption2: caption2.apply(color: color, backgroundColor: backgroundColor),
      caption3: caption3.apply(color: color, backgroundColor: backgroundColor),
      caption4: caption4.apply(color: color, backgroundColor: backgroundColor),
      caption5: caption5.apply(color: color, backgroundColor: backgroundColor),
      caption6: caption6.apply(color: color, backgroundColor: backgroundColor),
      notificationCaption:
          notificationCaption.apply(color: color, backgroundColor: backgroundColor),
    );
  }

  @override
  ThemeExtension<AdsTextThemesExtension> lerp(
    covariant ThemeExtension<AdsTextThemesExtension>? other,
    double t,
  ) {
    if (other is! AdsTextThemesExtension) {
      return this;
    }

    return AdsTextThemesExtension(
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
