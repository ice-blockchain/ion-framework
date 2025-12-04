import 'package:ion_ads/src/appodeal/appodeal_platform_arguments.dart';

/// This is the configuration of ad choice view.
class AdChoiceConfig with AppodealPlatformArguments {
  AdChoiceConfig({
    this.position = AdChoicePosition.endTop,
  });

  final AdChoicePosition position;

  @override
  Map<String, dynamic> get toMap => <String, dynamic>{
        'position': position.index,
      };
}

enum AdChoicePosition { startTop, startBottom, endTop, endBottom }
