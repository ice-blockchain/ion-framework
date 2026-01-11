import 'package:flutter/material.dart';
import 'package:ion_ads/src/appodeal/appodeal_platform_arguments.dart';
import 'package:ion_ads/src/appodeal/native_ad/native_color_apis.dart';

/// This is the configuration of call to action button that will do a action,
/// eg: INSTALL app, VISIT website, DOWNLOAD app.
class AdActionButtonConfig with AppodealPlatformArguments {
  AdActionButtonConfig({
    this.fontSize = 14,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.transparent,
    this.margin = 0,
    this.radius = 8,
    this.position = AdActionPosition.top,
  });

  final Color textColor;
  final Color backgroundColor;
  final int fontSize;
  final int margin;
  final int radius;
  final AdActionPosition position;

  @override
  Map<String, dynamic> get toMap => <String, dynamic>{
        'fontSize': fontSize,
        'textColor': textColor.toHex(),
        'backgroundColor': backgroundColor.toHex(),
        'margin': margin,
        'radius': radius,
        'position': position.index,
      };
}

enum AdActionPosition { top, bottom }
