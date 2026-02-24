// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/slider/slider.dart';
import 'package:ion/app/extensions/extensions.dart';

class AppSlider extends HookWidget {
  const AppSlider({
    required this.onChanged,
    super.key,
    this.initialValue = 15.0,
    this.stops = const <double>[0, 15, 30, 45],
    this.maxValue = 45.0,
    this.minValue = 0.0,
    this.stepValue = 15.0,
    this.sliderHeight = 40.0,
    this.trackBarHeight = 2.0,
    this.thumbIconSize = 34.0,
    this.markerSize = 8.0,
    this.markerRadius = 3.0,
    this.resistance = 0,
  });

  final double initialValue;
  final List<double> stops;
  final void Function(double) onChanged;
  final double maxValue;
  final double minValue;
  final double stepValue;
  final double sliderHeight;
  final double trackBarHeight;
  final double thumbIconSize;
  final double markerSize;
  final double markerRadius;
  final double resistance;

  @override
  Widget build(BuildContext context) {
    final sliderValue = useState(initialValue);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 100),
      initialValue: initialValue / maxValue,
    );

    useEffect(
      () {
        animationController.animateTo(sliderValue.value / maxValue);
        return null;
      },
      <Object?>[sliderValue.value],
    );

    useEffect(
      () {
        void listener() {
          onChanged(sliderValue.value);
        }

        sliderValue.addListener(listener);

        return () => sliderValue.removeListener(listener);
      },
      [sliderValue],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final sliderWidth = constraints.maxWidth;
        final animation = animationController.drive(
          Tween<double>(
            begin: 0,
            end: sliderWidth,
          ),
        );

        return GestureDetector(
          onPanUpdate: (DragUpdateDetails details) => _handlePanUpdate(
            context,
            details,
            sliderWidth,
            sliderValue,
          ),
          onPanEnd: (DragEndDetails details) => _handlePanEnd(sliderValue, stops),
          child: SizedBox(
            width: sliderWidth,
            height: sliderHeight.s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TrackBar.inactive(
                  trackBarHeight: trackBarHeight,
                  color: context.theme.appColors.onTertiaryFill,
                ),
                AnimatedBuilder(
                  animation: animationController,
                  builder: (BuildContext context, Widget? child) {
                    return PositionedDirectional(
                      start: 0.0.s,
                      child: TrackBar.active(
                        trackBarHeight: trackBarHeight,
                        color: context.theme.appColors.primaryAccent,
                        width: animation.value,
                      ),
                    );
                  },
                ),
                Markers(
                  stops: stops,
                  sliderValue: sliderValue,
                  markerSize: markerSize.s,
                  tapAreaSize: sliderHeight.s,
                  markerRadius: markerRadius.s,
                  onMarkerTapped: (double stop) {
                    sliderValue.value = stop;
                  },
                ),
                AnimatedBuilder(
                  animation: animationController,
                  builder: (BuildContext context, Widget? child) {
                    return PositionedDirectional(
                      start: SliderUtils.computeSliderOffset(
                        value: animation.value,
                        sliderWidth: sliderWidth,
                        thumbSize: thumbIconSize.s,
                      ),
                      child: child!,
                    );
                  },
                  child: SliderThumb(
                    sliderValue: sliderValue,
                    sliderWidth: sliderWidth,
                    thumbIconSize: thumbIconSize.s,
                    maxValue: maxValue,
                    minValue: minValue,
                    stops: stops,
                    resistance: resistance,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePanUpdate(
    BuildContext context,
    DragUpdateDetails details,
    double sliderWidth,
    ValueNotifier<double> sliderValue,
  ) {
    final localPosition = SliderUtils.getLocalPosition(
      context,
      details.globalPosition,
    );
    final newValue = SliderUtils.calculateNewValue(
      localPosition: localPosition,
      sliderWidth: sliderWidth,
      minValue: minValue,
      maxValue: maxValue,
    );

    sliderValue.value = SliderUtils.findClosestStop(
      currentValue: newValue,
      stops: stops,
      resistance: resistance,
    );
  }

  void _handlePanEnd(ValueNotifier<double> sliderValue, List<double> stops) {
    sliderValue.value = SliderUtils.findClosestStop(
      currentValue: sliderValue.value,
      stops: stops,
      resistance: resistance,
    );
  }
}
