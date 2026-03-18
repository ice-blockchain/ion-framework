// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/icon_slider.dart';

class BoostSliderRow extends StatelessWidget {
  const BoostSliderRow({
    required this.label,
    required this.value,
    required this.currentValue,
    required this.onChanged,
    required this.icon,
    this.min,
    this.max,
    this.predefinedValues,
    super.key,
  }) : assert(
          (min != null && max != null && predefinedValues == null) ||
              (predefinedValues != null && min == null && max == null),
          'Either provide min/max OR predefinedValues, not both',
        );

  final String label;
  final String value;
  final double? min;
  final double? max;
  final List<double>? predefinedValues;
  final double currentValue;
  final ValueChanged<double> onChanged;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final usesPredefinedValues = predefinedValues != null;
    final effectiveMin = usesPredefinedValues ? 0.0 : min!;
    final effectiveMax = usesPredefinedValues ? (predefinedValues!.length - 1).toDouble() : max!;
    final sliderValue =
        usesPredefinedValues ? predefinedValues!.indexOf(currentValue).toDouble() : currentValue;
    final divisions = usesPredefinedValues ? predefinedValues!.length - 1 : (max! - min!).round();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: context.theme.appTextThemes.body2.copyWith(
                color: context.theme.appColors.primaryText,
              ),
            ),
            Text(
              value,
              style: context.theme.appTextThemes.body2.copyWith(
                color: context.theme.appColors.primaryAccent,
              ),
            ),
          ],
        ),
        IonIconSlider(
          sliderValue: sliderValue,
          effectiveMin: effectiveMin,
          effectiveMax: effectiveMax,
          icon: icon,
          divisions: divisions,
          onChanged: onChanged,
          predefinedValues: predefinedValues,
        ),
      ],
    );
  }
}
