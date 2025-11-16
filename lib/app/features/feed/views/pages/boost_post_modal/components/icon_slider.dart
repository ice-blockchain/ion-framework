import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart' as vg;
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class IonIconSlider extends StatefulWidget {
  const IonIconSlider({
    required this.sliderValue,
    required this.effectiveMin,
    required this.effectiveMax,
    required this.icon,
    required this.divisions,
    required this.onChanged,
    this.predefinedValues,
    super.key,
  });

  final double sliderValue;
  final double effectiveMin;
  final double effectiveMax;
  final String icon;
  final int divisions;
  final ValueChanged<double> onChanged;
  final List<double>? predefinedValues;

  @override
  State<IonIconSlider> createState() => IonIconSliderState();
}

class IonIconSliderState extends State<IonIconSlider> {
  // Cache for loaded SVG pictures
  static ui.Picture? _cachedOuterPicture;
  static ui.Picture? _cachedBgPicture;
  static final Map<String, ui.Picture> _cachedInnerPictures = {};

  _SliderPictures? _pictures;
  bool _isLoading = false;

  String get _innerIconPath => widget.icon;

  @override
  void initState() {
    super.initState();
    _loadSvgPictures();
  }

  Future<void> _loadSvgPictures() async {
    if (_isLoading) return;

    // Check if all pictures are already cached
    if (_cachedOuterPicture != null &&
        _cachedBgPicture != null &&
        _cachedInnerPictures.containsKey(_innerIconPath)) {
      setState(() {
        _pictures = _SliderPictures(
          outerPicture: _cachedOuterPicture!,
          bgPicture: _cachedBgPicture!,
          innerPicture: _cachedInnerPictures[_innerIconPath]!,
        );
      });
      return;
    }

    _isLoading = true;
    try {
      // Load outer SVG
      if (_cachedOuterPicture == null) {
        final outerRawSvg = await rootBundle.loadString(Assets.svg.iconOuterSlider);
        final outerLoader = vg.SvgStringLoader(outerRawSvg);
        final outerPictureInfo = await vg.vg.loadPicture(outerLoader, null);
        _cachedOuterPicture = outerPictureInfo.picture;
      }

      // Load background SVG
      if (_cachedBgPicture == null) {
        final bgRawSvg = await rootBundle.loadString(Assets.svg.iconInnerSlider);
        final bgLoader = vg.SvgStringLoader(bgRawSvg);
        final bgPictureInfo = await vg.vg.loadPicture(bgLoader, null);
        _cachedBgPicture = bgPictureInfo.picture;
      }

      // Load inner SVG (required)
      if (!_cachedInnerPictures.containsKey(_innerIconPath)) {
        final innerRawSvg = await rootBundle.loadString(_innerIconPath);
        final innerLoader = vg.SvgStringLoader(innerRawSvg);
        final innerPictureInfo = await vg.vg.loadPicture(innerLoader, null);
        _cachedInnerPictures[_innerIconPath] = innerPictureInfo.picture;
      }
      if (mounted &&
          _cachedOuterPicture != null &&
          _cachedBgPicture != null &&
          _cachedInnerPictures.containsKey(_innerIconPath)) {
        setState(() {
          _pictures = _SliderPictures(
            outerPicture: _cachedOuterPicture!,
            bgPicture: _cachedBgPicture!,
            innerPicture: _cachedInnerPictures[_innerIconPath]!,
          );
        });
      }
    } catch (e) {
      // If loading fails, pictures remain null
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 34.0.s;

    return SizedBox(
      height: 40.0.s,
      width: double.infinity, // Make it occupy full screen width
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 2.0.s,
          activeTrackColor: context.theme.appColors.primaryAccent,
          inactiveTrackColor: context.theme.appColors.onTertiaryFill,
          thumbColor: Colors.transparent,
          overlayColor: context.theme.appColors.primaryAccent.withValues(alpha: 0.2),
          thumbShape: _pictures != null
              ? _IconSliderThumbShape(
                  iconSize: iconSize,
                  outerPicture: _pictures!.outerPicture,
                  bgPicture: _pictures!.bgPicture,
                  innerPicture: _pictures!.innerPicture,
                  iconColor: context.theme.appColors.primaryAccent,
                )
              : _EmptySliderComponentShape(iconSize: iconSize),
          overlayShape: _EmptySliderComponentShape(iconSize: iconSize),
          tickMarkShape: SliderTickMarkShape.noTickMark,
          trackShape: const _FullWidthSliderTrackShape(),
        ),
        child: Slider(
          value: widget.sliderValue,
          min: widget.effectiveMin,
          max: widget.effectiveMax,
          divisions: widget.divisions,
          onChanged: (value) {
            if (widget.predefinedValues != null) {
              final index = value.round();
              widget.onChanged(widget.predefinedValues![index]);
            } else {
              widget.onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

/// Container for all three SVG pictures
class _SliderPictures {
  const _SliderPictures({
    required this.outerPicture,
    required this.bgPicture,
    required this.innerPicture,
  });

  final ui.Picture outerPicture;
  final ui.Picture bgPicture;
  final ui.Picture innerPicture;
}

/// Custom track shape that extends to full width while keeping thumb constrained
class _FullWidthSliderTrackShape extends SliderTrackShape {
  const _FullWidthSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    Offset offset = Offset.zero,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight!;
    assert(trackHeight >= 0, 'Track height must be greater than 0');

    // If the track colors are transparent, then override only the track height
    // to maintain overall Slider width.
    if (sliderTheme.activeTrackColor == Colors.transparent &&
        sliderTheme.inactiveTrackColor == Colors.transparent) {
      return Rect.fromLTWH(offset.dx, offset.dy, 0, 0);
    }

    // Get thumb and overlay sizes to constrain thumb within track bounds
    final thumbWidth = sliderTheme.thumbShape!.getPreferredSize(isEnabled, isDiscrete).width;
    final overlayWidth = sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width;
    final thumbRadius = thumbWidth / 2;
    final maxRadius = thumbRadius > overlayWidth / 2 ? thumbRadius : overlayWidth / 2;

    // Constrain track rect to keep thumb center within bounds
    // Track will be painted full width in paint(), but thumb positioning uses this constrained rect
    final trackLeft = offset.dx + maxRadius;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackRight = offset.dx + parentBox.size.width - maxRadius;
    final trackBottom = trackTop + trackHeight;

    // Ensure trackRight >= trackLeft (in case parentBox is too small)
    return Rect.fromLTRB(
      trackLeft,
      trackTop,
      trackRight > trackLeft ? trackRight : trackLeft,
      trackBottom,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    assert(
      sliderTheme.disabledActiveTrackColor != null,
      'Disabled active track color must be provided',
    );
    assert(
      sliderTheme.disabledInactiveTrackColor != null,
      'Disabled inactive track color must be provided',
    );
    assert(sliderTheme.activeTrackColor != null, 'Active track color must be provided');
    assert(sliderTheme.inactiveTrackColor != null, 'Inactive track color must be provided');

    // If the slider [SliderThemeData.trackHeight] is less than or equal to 0,
    // then it makes no difference whether the track is painted or not,
    // therefore the painting can be a no-op.
    if (sliderTheme.trackHeight! <= 0) {
      return;
    }

    // Paint track at full width (extending beyond trackRect used for thumb positioning)
    final fullTrackLeft = offset.dx;
    final fullTrackTop = offset.dy + (parentBox.size.height - sliderTheme.trackHeight!) / 2;
    final fullTrackRight = offset.dx + parentBox.size.width;
    final fullTrackBottom = fullTrackTop + sliderTheme.trackHeight!;
    final fullTrackRect = Rect.fromLTRB(
      fullTrackLeft,
      fullTrackTop,
      fullTrackRight,
      fullTrackBottom,
    );

    final activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );
    final activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    // Handle text direction for RTL support
    final (Paint leftTrackPaint, Paint rightTrackPaint) = switch (textDirection) {
      TextDirection.ltr => (activePaint, inactivePaint),
      TextDirection.rtl => (inactivePaint, activePaint),
    };

    // Paint inactive track (full width)
    context.canvas.drawRect(
      fullTrackRect,
      rightTrackPaint,
    );

    // Paint active track (from start to thumb center, using full-width track)
    final activeTrackRect = switch (textDirection) {
      TextDirection.ltr => Rect.fromLTRB(
          fullTrackRect.left,
          fullTrackRect.top,
          thumbCenter.dx,
          fullTrackRect.bottom,
        ),
      TextDirection.rtl => Rect.fromLTRB(
          thumbCenter.dx,
          fullTrackRect.top,
          fullTrackRect.right,
          fullTrackRect.bottom,
        ),
    };
    context.canvas.drawRect(
      activeTrackRect,
      leftTrackPaint,
    );

    // Paint secondary track if provided
    if (secondaryOffset != null) {
      final secondaryActiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledSecondaryActiveTrackColor,
        end: sliderTheme.secondaryActiveTrackColor,
      );
      final secondaryPaint = Paint()
        ..color = secondaryActiveTrackColorTween.evaluate(enableAnimation)!;
      final secondaryTrackRect = Rect.fromLTRB(
        thumbCenter.dx,
        fullTrackRect.top,
        secondaryOffset.dx,
        fullTrackRect.bottom,
      );
      context.canvas.drawRect(
        secondaryTrackRect,
        secondaryPaint,
      );
    }
  }
}

/// Empty thumb shape that just reserves space while pictures are loading
class _EmptySliderComponentShape extends SliderComponentShape {
  const _EmptySliderComponentShape({
    required this.iconSize,
  });

  final double iconSize;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(iconSize, iconSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    // Don't paint anything, just reserve space
  }
}

/// Custom thumb shape that paints the SVG icon (synchronous, requires preloaded pictures)
class _IconSliderThumbShape extends SliderComponentShape {
  const _IconSliderThumbShape({
    required this.iconSize,
    required this.outerPicture,
    required this.bgPicture,
    required this.innerPicture,
    this.iconColor,
  });

  final double iconSize;
  final ui.Picture outerPicture;
  final ui.Picture bgPicture;
  final ui.Picture innerPicture;
  final Color? iconColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(iconSize, iconSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Calculate the rect to draw the icon centered at the thumb position
    final iconRect = Rect.fromCenter(
      center: center,
      width: iconSize,
      height: iconSize,
    );

    // SVG viewBox sizes - these come from the SVG files' viewBox or width/height attributes:
    // - icon_outer_slider.svg: viewBox="0 0 34 34" → 34x34
    // - icon_inner_slider.svg: viewBox="0 0 26 26" → 26x26
    // - icon_field_calendar.svg: width="24" height="24" → 24x24
    const outerSvgSize = 34.0; // From icon_outer_slider.svg viewBox
    const bgSvgSize = 26.0; // From icon_inner_slider.svg viewBox
    const innerSvgSize = 24.0; // From icon_field_calendar.svg width/height

    canvas
      ..save()
      ..translate(iconRect.left, iconRect.top);

    // 1. Draw outer SVG (bottom layer) with color filter if provided
    // Outer SVG is 34x34, scale it to fit iconSize (which is also 34px)
    final outerScale = iconSize / outerSvgSize;
    if (iconColor != null) {
      final paint = Paint()..colorFilter = ColorFilter.mode(iconColor!, BlendMode.srcIn);
      final outerRect = Rect.fromLTWH(0, 0, iconSize, iconSize);
      canvas
        ..saveLayer(outerRect, paint)
        ..scale(outerScale)
        ..drawPicture(outerPicture)
        ..restore();
    } else {
      canvas
        ..scale(outerScale)
        ..drawPicture(outerPicture);
    }

    // 2. Draw background SVG (middle layer) - centered within iconSize container
    // Background SVG is 26x26, draw it at its natural size centered
    final bgScaledSize = bgSvgSize * (iconSize / outerSvgSize); // Scale relative to outer
    final bgOffsetX = (iconSize - bgScaledSize) / 2;
    final bgOffsetY = (iconSize - bgScaledSize) / 2;
    final bgScale = iconSize / outerSvgSize; // Same scale as outer

    canvas
      ..save()
      ..translate(bgOffsetX, bgOffsetY)
      ..scale(bgScale)
      ..drawPicture(bgPicture)
      ..restore();

    // 3. Draw inner SVG (top layer) - centered within bg area with color filter if provided
    // Inner SVG should be painted at exactly 20.s pixels
    final targetInnerSize = 20.0.s;
    final innerScale = targetInnerSize / innerSvgSize; // Scale to achieve target size
    final innerOffsetX = (iconSize - targetInnerSize) / 2;
    final innerOffsetY = (iconSize - targetInnerSize) / 2;

    if (iconColor != null) {
      final paint = Paint()..colorFilter = ColorFilter.mode(iconColor!, BlendMode.srcIn);
      final innerRect = Rect.fromLTWH(
        innerOffsetX,
        innerOffsetY,
        targetInnerSize,
        targetInnerSize,
      );
      canvas
        ..saveLayer(innerRect, paint)
        ..translate(innerOffsetX, innerOffsetY)
        ..scale(innerScale)
        ..drawPicture(innerPicture)
        ..restore();
    } else {
      canvas
        ..save()
        ..translate(innerOffsetX, innerOffsetY)
        ..scale(innerScale)
        ..drawPicture(innerPicture)
        ..restore();
    }

    canvas.restore();
  }
}
