// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';

class Markers extends HookWidget {
  const Markers({
    required this.stops,
    required this.sliderValue,
    required this.markerSize,
    required this.markerRadius,
    required this.onMarkerTapped,
    required this.tapAreaSize,
    super.key,
  });

  final List<double> stops;
  final ValueNotifier<double> sliderValue;
  final double markerSize;
  final double markerRadius;
  final void Function(double) onMarkerTapped;
  final double tapAreaSize;

  @override
  Widget build(BuildContext context) {
    final double currentSliderValue = useValueListenable(sliderValue);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: stops.map((double stop) {
        return GestureDetector(
          onTap: () => onMarkerTapped(stop),
          child: Container(
            width: tapAreaSize.s,
            height: tapAreaSize.s,
            color: Colors.transparent,
            alignment: _getAlignment(stop),
            child: Container(
              width: markerSize.s,
              height: markerSize.s,
              decoration: BoxDecoration(
                color: stop <= currentSliderValue
                    ? context.theme.appColors.primaryAccent
                    : context.theme.appColors.onTertiaryFill,
                borderRadius: BorderRadius.circular(markerRadius.s),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Alignment _getAlignment(double stop) {
    if (stop == stops.first) {
      return Alignment.centerLeft;
    } else if (stop == stops.last) {
      return Alignment.centerRight;
    }

    return Alignment.center;
  }
}
