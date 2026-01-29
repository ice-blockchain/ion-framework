// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

/// Defines consistent spacing, padding, and size constants for the ad UI,
/// integrated into the theme system via ThemeExtension.
@immutable
class AdsSpacingExtension extends ThemeExtension<AdsSpacingExtension> {
  const AdsSpacingExtension({
    required this.marginContainer,
    required this.paddingInnerHorizontal,
    required this.paddingInnerVertical,
    required this.spacingM,
    required this.spacingS,
    required this.iconSizeDefault,
    required this.iconSizeLarge,
    required this.starRatingSize,
    required this.borderRadiusDefault,
    required this.screenEdge,
  });

  /// Factory constructor to easily provide the default ad spacing data.
  factory AdsSpacingExtension.defaultSpacing() {
    return const AdsSpacingExtension(
      // Layout Margins & Outer Padding (Large Spacing)
      marginContainer: 12,
      paddingInnerHorizontal: 12,
      paddingInnerVertical: 6,
      // Component Spacing (Small to Medium Gaps)
      spacingM: 8,
      spacingS: 4,
      // Dimensions
      iconSizeDefault: 32,
      iconSizeLarge: 48,
      starRatingSize: 12,
      borderRadiusDefault: 10,
      // Global screen padding (e.g., used outside the ad card)
      screenEdge: 16,
    );
  }

  // --- Properties ---
  final double marginContainer;
  final double paddingInnerHorizontal;
  final double paddingInnerVertical;
  final double spacingM;
  final double spacingS;
  final double iconSizeDefault;
  final double iconSizeLarge;
  final double starRatingSize;
  final double borderRadiusDefault;
  final double screenEdge;

  // --- ThemeExtension Implementation ---

  @override
  AdsSpacingExtension copyWith({
    double? marginContainer,
    double? paddingInnerHorizontal,
    double? paddingInnerVertical,
    double? spacingM,
    double? spacingS,
    double? iconSizeDefault,
    double? iconSizeLarge,
    double? starRatingSize,
    double? borderRadiusDefault,
    double? screenEdge,
  }) {
    return AdsSpacingExtension(
      marginContainer: marginContainer ?? this.marginContainer,
      paddingInnerHorizontal: paddingInnerHorizontal ?? this.paddingInnerHorizontal,
      paddingInnerVertical: paddingInnerVertical ?? this.paddingInnerVertical,
      spacingM: spacingM ?? this.spacingM,
      spacingS: spacingS ?? this.spacingS,
      iconSizeDefault: iconSizeDefault ?? this.iconSizeDefault,
      iconSizeLarge: iconSizeLarge ?? this.iconSizeLarge,
      starRatingSize: starRatingSize ?? this.starRatingSize,
      borderRadiusDefault: borderRadiusDefault ?? this.borderRadiusDefault,
      screenEdge: screenEdge ?? this.screenEdge,
    );
  }

  @override
  AdsSpacingExtension lerp(
    covariant ThemeExtension<AdsSpacingExtension>? other,
    double t,
  ) {
    if (other is! AdsSpacingExtension) {
      return this;
    }

    return AdsSpacingExtension(
      marginContainer: _lerpDouble(marginContainer, other.marginContainer, t)!,
      paddingInnerHorizontal: _lerpDouble(paddingInnerHorizontal, other.paddingInnerHorizontal, t)!,
      paddingInnerVertical: _lerpDouble(paddingInnerVertical, other.paddingInnerVertical, t)!,
      spacingM: _lerpDouble(spacingM, other.spacingM, t)!,
      spacingS: _lerpDouble(spacingS, other.spacingS, t)!,
      iconSizeDefault: _lerpDouble(iconSizeDefault, other.iconSizeDefault, t)!,
      iconSizeLarge: _lerpDouble(iconSizeLarge, other.iconSizeLarge, t)!,
      starRatingSize: _lerpDouble(starRatingSize, other.starRatingSize, t)!,
      borderRadiusDefault: _lerpDouble(borderRadiusDefault, other.borderRadiusDefault, t)!,
      screenEdge: _lerpDouble(screenEdge, other.screenEdge, t)!,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b! * t;
    if (b == null) return a * (1.0 - t);
    return a + (b - a) * t;
  }
}
