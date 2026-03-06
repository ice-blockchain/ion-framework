// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/config/ads_colors.dart';
import 'package:ion_ads/src/config/ads_text_themes.dart';
import 'package:ion_ads/src/config/theme_paddings.dart';

extension AppThemeExtension on ThemeData {
  /// Usage example: Theme.of(context).adsColors;
  AdsColorsExtension get adsColors =>
      extension<AdsColorsExtension>() ?? AdsColorsExtension.defaultColors();

  /// Usage example: Theme.of(context).adsTextThemes;
  AdsTextThemesExtension get adsTextThemes =>
      extension<AdsTextThemesExtension>() ?? AdsTextThemesExtension.defaultTextThemes();

  /// These are Extension for text colors from AdsTextThemesExtension
  /// Usage example: theme.textPrimary.subtitle2;
  AdsTextThemesExtension get textPrimary => adsTextThemes.apply(color: adsColors.primaryText);

  /// Usage example: theme.textOnPrimary.body;
  AdsTextThemesExtension get textOnPrimary => adsTextThemes.apply(color: adsColors.onPrimaryAccent);
}

extension AdsTextColorExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  AdsColorsExtension get colors => theme.adsColors;

  AdsTextThemesExtension get textPrimary => theme.textPrimary;
}

extension AdsThemeData on ThemeData {
  /// Provides easy access to ad-specific spacing and sizing constants.
  AdsSpacingExtension get adsSpacing =>
      extension<AdsSpacingExtension>() ?? AdsSpacingExtension.defaultSpacing();
}
