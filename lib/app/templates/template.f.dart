// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/templates/converters.dart';

part 'template.f.freezed.dart';
part 'template.f.g.dart';

@freezed
class TemplateColors with _$TemplateColors {
  @JsonSerializable(
    converters: <JsonConverter<dynamic, String>>[ColorConverter()],
  )
  const factory TemplateColors(
    Color primaryAccent,
    Color primaryText,
    Color secondaryText,
    Color tertiaryText,
    Color primaryBackground,
    Color secondaryBackground,
    Color tertiaryBackground,
    Color backgroundSheet,
    Color onPrimaryAccent,
    Color onTertiaryBackground,
    Color onTertiaryFill,
    Color onSecondaryBackground,
    Color strokeElements,
    Color sheetLine,
    Color sharkText,
    Color attentionRed,
    Color success,
    Color orangePeel,
    Color purple,
    Color raspberry,
    Color darkBlue,
    Color darkNight,
    Color lightBlue,
    Color quaternaryText,
    Color attentionBlock,
    Color pink,
    Color medBlue,
    Color postContent,
    Color lossRed,
    Color anakiwa,
    Color shadow,
    Color profitGreen,
  ) = _TemplateColors;

  factory TemplateColors.fromJson(Map<String, dynamic> json) => _$TemplateColorsFromJson(json);

  factory TemplateColors.empty() => const TemplateColors(
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
      );
}

@freezed
class TemplateColorsLightDark with _$TemplateColorsLightDark {
  const factory TemplateColorsLightDark(
    TemplateColors light,
    TemplateColors dark,
  ) = _TemplateColorsLightDark;

  factory TemplateColorsLightDark.fromJson(Map<String, dynamic> json) =>
      _$TemplateColorsLightDarkFromJson(json);

  factory TemplateColorsLightDark.empty() => TemplateColorsLightDark(
        TemplateColors.empty(),
        TemplateColors.empty(),
      );
}

@freezed
class TemplateAppBarTheme with _$TemplateAppBarTheme {
  const factory TemplateAppBarTheme(double toolbarHeight) = _TemplateAppBarTheme;

  factory TemplateAppBarTheme.fromJson(Map<String, dynamic> json) =>
      _$TemplateAppBarThemeFromJson(json);

  factory TemplateAppBarTheme.empty() => const TemplateAppBarTheme(0);
}

@freezed
class TemplateTextTheme with _$TemplateTextTheme {
  const factory TemplateTextTheme(
    double? fontSize,
    double? height,
    @FontWeightConverter() FontWeight? fontWeight,
  ) = _TemplateTextTheme;

  factory TemplateTextTheme.fromJson(Map<String, dynamic> json) =>
      _$TemplateTextThemeFromJson(json);

  factory TemplateTextTheme.empty() => const TemplateTextTheme(
        null,
        null,
        null,
      );
}

@freezed
class TemplateTextThemes with _$TemplateTextThemes {
  const factory TemplateTextThemes(
    TemplateTextTheme headline1,
    TemplateTextTheme headline2,
    TemplateTextTheme title,
    TemplateTextTheme subtitle,
    TemplateTextTheme subtitle2,
    TemplateTextTheme subtitle3,
    TemplateTextTheme body,
    TemplateTextTheme body2,
    TemplateTextTheme caption,
    TemplateTextTheme caption2,
    TemplateTextTheme caption3,
    TemplateTextTheme caption4,
    TemplateTextTheme caption5,
    TemplateTextTheme caption6,
    TemplateTextTheme notificationCaption,
  ) = _TemplateTextThemes;

  factory TemplateTextThemes.fromJson(Map<String, dynamic> json) =>
      _$TemplateTextThemesFromJson(json);

  factory TemplateTextThemes.empty() => TemplateTextThemes(
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
        TemplateTextTheme.empty(),
      );
}

@freezed
class TemplateMenuTheme with _$TemplateMenuTheme {
  const factory TemplateMenuTheme(
    double elevation,
    double borderRadius,
    double paddingLeft,
    double paddingTop,
    double paddingRight,
    double paddingBottom,
  ) = _TemplateMenuTheme;

  factory TemplateMenuTheme.fromJson(Map<String, dynamic> json) =>
      _$TemplateMenuThemeFromJson(json);

  factory TemplateMenuTheme.empty() => const TemplateMenuTheme(
        0,
        0,
        0,
        0,
        0,
        0,
      );
}

@freezed
class TemplateMenuButtonTheme with _$TemplateMenuButtonTheme {
  const factory TemplateMenuButtonTheme(
    double minHeight,
    double paddingLeft,
    double paddingTop,
    double paddingRight,
    double paddingBottom,
  ) = _TemplateMenuButtonTheme;

  factory TemplateMenuButtonTheme.fromJson(Map<String, dynamic> json) =>
      _$TemplateMenuButtonThemeFromJson(json);

  factory TemplateMenuButtonTheme.empty() => const TemplateMenuButtonTheme(
        0,
        0,
        0,
        0,
        0,
      );
}

@freezed
class TemplateIconButtonTheme with _$TemplateIconButtonTheme {
  const factory TemplateIconButtonTheme({
    required double width,
    required double height,
  }) = _TemplateIconButtonTheme;

  factory TemplateIconButtonTheme.fromJson(Map<String, dynamic> json) =>
      _$TemplateIconButtonThemeFromJson(json);

  factory TemplateIconButtonTheme.empty() => const TemplateIconButtonTheme(
        width: 0,
        height: 0,
      );
}

@freezed
class TemplateIconTheme with _$TemplateIconTheme {
  const factory TemplateIconTheme({
    required double width,
    required double height,
  }) = _TemplateIconThem;

  factory TemplateIconTheme.fromJson(Map<String, dynamic> json) =>
      _$TemplateIconThemeFromJson(json);

  factory TemplateIconTheme.empty() => const TemplateIconTheme(
        width: 0,
        height: 0,
      );
}

@freezed
class TemplateTheme with _$TemplateTheme {
  const factory TemplateTheme(
    TemplateColorsLightDark colors,
    TemplateTextThemes textThemes,
    TemplateAppBarTheme appBar,
    TemplateMenuTheme menu,
    TemplateMenuButtonTheme menuButton,
    TemplateIconButtonTheme iconButton,
    TemplateIconTheme icon,
  ) = _TemplateTheme;

  factory TemplateTheme.fromJson(Map<String, dynamic> json) => _$TemplateThemeFromJson(json);

  factory TemplateTheme.empty() => TemplateTheme(
        TemplateColorsLightDark.empty(),
        TemplateTextThemes.empty(),
        TemplateAppBarTheme.empty(),
        TemplateMenuTheme.empty(),
        TemplateMenuButtonTheme.empty(),
        TemplateIconButtonTheme.empty(),
        TemplateIconTheme.empty(),
      );
}

@freezed
class Template with _$Template {
  const factory Template(
    TemplateTheme theme,
    TemplateConfig config,
  ) = _Template;

  factory Template.fromJson(Map<String, dynamic> json) => _$TemplateFromJson(json);
}

@freezed
class TemplateConfig with _$TemplateConfig {
  const factory TemplateConfig({
    Map<String, TemplateConfigPage>? pages,
  }) = _TemplateConfig;

  factory TemplateConfig.fromJson(Map<String, dynamic> json) => _$TemplateConfigFromJson(json);
}

abstract class TemplateConfigElement {
  bool? get hidden;
}

@freezed
class TemplateConfigPage with _$TemplateConfigPage implements TemplateConfigElement {
  const factory TemplateConfigPage({
    bool? hidden,
    Map<String, TemplateConfigComponent>? components,
  }) = _TemplateConfigPage;

  factory TemplateConfigPage.fromJson(Map<String, dynamic> json) =>
      _$TemplateConfigPageFromJson(json);
}

@freezed
class TemplateConfigComponent with _$TemplateConfigComponent implements TemplateConfigElement {
  const factory TemplateConfigComponent({
    bool? hidden,
    int? variant,
  }) = _TemplateConfigComponent;

  factory TemplateConfigComponent.fromJson(Map<String, dynamic> json) =>
      _$TemplateConfigComponentFromJson(json);
}
