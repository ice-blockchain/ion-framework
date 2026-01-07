import 'package:ion_ads/src/appodeal/appodeal_platform_arguments.dart';

/// This is the configuration of ad choice view.
class AdChoiceConfig with AppodealPlatformArguments {
  AdChoiceConfig({
    this.position = AdChoicePosition.endTop,
    this.margin = 0,
  });

  final AdChoicePosition position;
  final double margin;

  @override
  Map<String, dynamic> get toMap => <String, dynamic>{
        'position': position.index,
        'margin': margin,
      };
}

enum AdChoicePosition { startTop, startBottom, endTop, endBottom }
