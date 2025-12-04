import 'package:flutter/material.dart';
import 'package:ion_ads/src/appodeal/appodeal_platform_arguments.dart';
import 'package:ion_ads/src/appodeal/native_ad/native_color_apis.dart';

/// This is the configuration of title text.
class AdTitleConfig with AppodealPlatformArguments {
  AdTitleConfig({
    this.fontSize = 16,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.transparent,
    this.margin = 0,
  });

  final int fontSize;
  final Color textColor;
  final Color backgroundColor;
  final int margin;

  @override
  Map<String, dynamic> get toMap => <String, dynamic>{
        'fontSize': fontSize,
        'textColor': textColor.toHex(),
        'backgroundColor': backgroundColor.toHex(),
        'margin': margin,
      };
}
