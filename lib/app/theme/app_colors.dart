// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/templates/template.f.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  AppColorsExtension({
    required this.primaryAccent,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.sharkText,
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.backgroundSheet,
    required this.onPrimaryAccent,
    required this.onTertiaryBackground,
    required this.onTertiaryFill,
    required this.onSecondaryBackground,
    required this.strokeElements,
    required this.sheetLine,
    required this.attentionRed,
    required this.success,
    required this.orangePeel,
    required this.purple,
    required this.raspberry,
    required this.darkBlue,
    required this.darkNight,
    required this.lightBlue,
    required this.quaternaryText,
    required this.attentionBlock,
    required this.pink,
    required this.medBlue,
    required this.postContent,
    required this.lossRed,
    required this.anakiwa,
    required this.shadow,
    required this.profitGreen,
    required this.backgroundBlue,
    required this.magenta,
    required this.allports,
    required this.forest,
    required this.electricViolet,
    required this.heliotrope,
    required this.asphalt,
  });

  factory AppColorsExtension.fromTemplate(TemplateColors templateColors) {
    return AppColorsExtension(
      primaryAccent: templateColors.primaryAccent,
      primaryText: templateColors.primaryText,
      secondaryText: templateColors.secondaryText,
      tertiaryText: templateColors.tertiaryText,
      sharkText: templateColors.sharkText,
      primaryBackground: templateColors.primaryBackground,
      secondaryBackground: templateColors.secondaryBackground,
      tertiaryBackground: templateColors.tertiaryBackground,
      backgroundSheet: templateColors.backgroundSheet,
      onPrimaryAccent: templateColors.onPrimaryAccent,
      onTertiaryBackground: templateColors.onTertiaryBackground,
      onTertiaryFill: templateColors.onTertiaryFill,
      onSecondaryBackground: templateColors.onSecondaryBackground,
      strokeElements: templateColors.strokeElements,
      sheetLine: templateColors.sheetLine,
      attentionRed: templateColors.attentionRed,
      success: templateColors.success,
      orangePeel: templateColors.orangePeel,
      purple: templateColors.purple,
      raspberry: templateColors.raspberry,
      darkBlue: templateColors.darkBlue,
      darkNight: templateColors.darkNight,
      lightBlue: templateColors.lightBlue,
      quaternaryText: templateColors.quaternaryText,
      attentionBlock: templateColors.attentionBlock,
      pink: templateColors.pink,
      medBlue: templateColors.medBlue,
      postContent: templateColors.postContent,
      lossRed: templateColors.lossRed,
      anakiwa: templateColors.anakiwa,
      shadow: templateColors.shadow,
      profitGreen: templateColors.profitGreen,
      backgroundBlue: templateColors.backgroundBlue,
      magenta: templateColors.magenta,
      allports: templateColors.allports,
      forest: templateColors.forest,
      electricViolet: templateColors.electricViolet,
      heliotrope: templateColors.heliotrope,
      asphalt: templateColors.asphalt,
    );
  }

  factory AppColorsExtension.defaultColors() {
    return AppColorsExtension(
      primaryAccent: const Color(0xFF0166FF),
      primaryText: const Color(0xFF0E0E0E),
      secondaryText: const Color(0xFF494949),
      tertiaryText: const Color(0xFF9A9A9A),
      sharkText: const Color(0xFF333436),
      primaryBackground: const Color(0xFFF5F7FF),
      secondaryBackground: const Color(0xFFFFFFFF),
      tertiaryBackground: const Color(0xFFFAFBFF),
      backgroundSheet: const Color(0x32081532),
      onPrimaryAccent: const Color(0xFFFFFFFF),
      onTertiaryBackground: const Color(0xFF5A5E66),
      onTertiaryFill: const Color(0xFFE1EAF8),
      onSecondaryBackground: const Color(0xFFF5F7FF),
      strokeElements: const Color(0xFFCCCCCC),
      sheetLine: const Color(0xFFB8BCCA),
      attentionRed: const Color(0xFFFD4E4E),
      success: const Color(0xFF35D487),
      orangePeel: const Color(0xFFFFA143),
      purple: const Color(0xFF7D40FF),
      raspberry: const Color(0xFFEA3665),
      darkBlue: const Color(0xFF1D46EB),
      darkNight: const Color(0xFF082FCC),
      lightBlue: const Color(0xFF1B9CF0),
      quaternaryText: const Color(0xFF727689),
      attentionBlock: const Color(0xFFEEF1FF),
      pink: const Color(0xFFA640FF),
      medBlue: const Color(0xFF4340FF),
      postContent: const Color(0xFF0F1419),
      lossRed: const Color(0xFFFF396E),
      anakiwa: const Color(0xFF91D4FF),
      shadow: const Color(0xFF2D62D9),
      profitGreen: const Color(0xFF00FF00),
      backgroundBlue: const Color(0xFF0D265E),
      magenta: const Color(0xFF8F039B),
      allports: const Color(0xFF017C9F),
      forest: const Color(0xFF010008),
      electricViolet: const Color(0xFF6F2EFE),
      heliotrope: const Color(0xFF9973FD),
      asphalt: const Color(0xFF1D1E20),
    );
  }

  final Color primaryAccent;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color sharkText;
  final Color primaryBackground;
  final Color secondaryBackground;
  final Color tertiaryBackground;
  final Color backgroundSheet;
  final Color onPrimaryAccent;
  final Color onTertiaryBackground;
  final Color onTertiaryFill;
  final Color onSecondaryBackground;
  final Color strokeElements;
  final Color sheetLine;
  final Color attentionRed;
  final Color success;
  final Color orangePeel;
  final Color purple;
  final Color raspberry;
  final Color darkBlue;
  final Color darkNight;
  final Color lightBlue;
  final Color quaternaryText;
  final Color attentionBlock;
  final Color pink;
  final Color medBlue;
  final Color postContent;
  final Color lossRed;
  final Color anakiwa;
  final Color shadow;
  final Color profitGreen;
  final Color backgroundBlue;
  final Color magenta;
  final Color allports;
  final Color forest;
  final Color electricViolet;
  final Color heliotrope;
  final Color asphalt;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primaryAccent,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? sharkText,
    Color? primaryBackground,
    Color? secondaryBackground,
    Color? tertiaryBackground,
    Color? backgroundSheet,
    Color? onPrimaryAccent,
    Color? onTertiaryBackground,
    Color? onTertiaryFill,
    Color? onSecondaryBackground,
    Color? strokeElements,
    Color? sheetLine,
    Color? attentionRed,
    Color? success,
    Color? orangePeel,
    Color? purple,
    Color? raspberry,
    Color? darkBlue,
    Color? darkNight,
    Color? lightBlue,
    Color? quaternaryText,
    Color? attentionBlock,
    Color? pink,
    Color? medBlue,
    Color? postContent,
    Color? lossRed,
    Color? anakiwa,
    Color? shadow,
    Color? profitGreen,
    Color? backgroundBlue,
    Color? magenta,
    Color? allports,
    Color? forest,
    Color? electricViolet,
    Color? heliotrope,
    Color? asphalt,
  }) {
    return AppColorsExtension(
      primaryAccent: primaryAccent ?? this.primaryAccent,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      sharkText: sharkText ?? this.sharkText,
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      tertiaryBackground: tertiaryBackground ?? this.tertiaryBackground,
      backgroundSheet: backgroundSheet ?? this.backgroundSheet,
      onPrimaryAccent: onPrimaryAccent ?? this.onPrimaryAccent,
      onTertiaryBackground: onTertiaryBackground ?? this.onTertiaryBackground,
      onTertiaryFill: onTertiaryFill ?? this.onTertiaryFill,
      onSecondaryBackground: onSecondaryBackground ?? this.onSecondaryBackground,
      strokeElements: strokeElements ?? this.strokeElements,
      sheetLine: sheetLine ?? this.sheetLine,
      attentionRed: attentionRed ?? this.attentionRed,
      success: success ?? this.success,
      orangePeel: orangePeel ?? this.orangePeel,
      purple: purple ?? this.purple,
      raspberry: raspberry ?? this.raspberry,
      darkBlue: darkBlue ?? this.darkBlue,
      darkNight: darkNight ?? this.darkNight,
      lightBlue: lightBlue ?? this.lightBlue,
      quaternaryText: quaternaryText ?? this.quaternaryText,
      attentionBlock: attentionBlock ?? this.attentionBlock,
      pink: pink ?? this.pink,
      medBlue: medBlue ?? this.medBlue,
      postContent: postContent ?? this.postContent,
      lossRed: lossRed ?? this.lossRed,
      anakiwa: anakiwa ?? this.anakiwa,
      shadow: shadow ?? this.shadow,
      profitGreen: profitGreen ?? this.profitGreen,
      backgroundBlue: backgroundBlue ?? this.backgroundBlue,
      magenta: magenta ?? this.magenta,
      allports: allports ?? this.allports,
      forest: forest ?? this.forest,
      electricViolet: electricViolet ?? this.electricViolet,
      heliotrope: heliotrope ?? this.heliotrope,
      asphalt: asphalt ?? this.asphalt,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }

    return AppColorsExtension(
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      sharkText: Color.lerp(sharkText, other.sharkText, t)!,
      primaryBackground: Color.lerp(primaryBackground, other.primaryBackground, t)!,
      secondaryBackground: Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      tertiaryBackground: Color.lerp(tertiaryBackground, other.tertiaryBackground, t)!,
      backgroundSheet: Color.lerp(backgroundSheet, other.backgroundSheet, t)!,
      onPrimaryAccent: Color.lerp(onPrimaryAccent, other.onPrimaryAccent, t)!,
      onTertiaryBackground: Color.lerp(onTertiaryBackground, other.onTertiaryBackground, t)!,
      onTertiaryFill: Color.lerp(onTertiaryFill, other.onTertiaryFill, t)!,
      onSecondaryBackground: Color.lerp(onSecondaryBackground, other.onSecondaryBackground, t)!,
      strokeElements: Color.lerp(strokeElements, other.strokeElements, t)!,
      sheetLine: Color.lerp(sheetLine, other.sheetLine, t)!,
      attentionRed: Color.lerp(attentionRed, other.attentionRed, t)!,
      success: Color.lerp(success, other.success, t)!,
      orangePeel: Color.lerp(orangePeel, other.orangePeel, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      raspberry: Color.lerp(raspberry, other.raspberry, t)!,
      darkBlue: Color.lerp(darkBlue, other.darkBlue, t)!,
      darkNight: Color.lerp(darkNight, other.darkNight, t)!,
      lightBlue: Color.lerp(lightBlue, other.lightBlue, t)!,
      quaternaryText: Color.lerp(quaternaryText, other.quaternaryText, t)!,
      attentionBlock: Color.lerp(attentionBlock, other.attentionBlock, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      medBlue: Color.lerp(medBlue, other.medBlue, t)!,
      postContent: Color.lerp(postContent, other.postContent, t)!,
      lossRed: Color.lerp(lossRed, other.lossRed, t)!,
      anakiwa: Color.lerp(anakiwa, other.anakiwa, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      profitGreen: Color.lerp(profitGreen, other.profitGreen, t)!,
      backgroundBlue: Color.lerp(backgroundBlue, other.backgroundBlue, t)!,
      magenta: Color.lerp(magenta, other.magenta, t)!,
      allports: Color.lerp(allports, other.allports, t)!,
      forest: Color.lerp(forest, other.forest, t)!,
      electricViolet: Color.lerp(electricViolet, other.electricViolet, t)!,
      heliotrope: Color.lerp(heliotrope, other.heliotrope, t)!,
      asphalt: Color.lerp(asphalt, other.asphalt, t)!,
    );
  }
}
