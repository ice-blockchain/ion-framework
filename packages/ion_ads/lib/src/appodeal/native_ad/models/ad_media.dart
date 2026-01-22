// SPDX-License-Identifier: ice License 1.0

import 'package:ion_ads/src/appodeal/appodeal_platform_arguments.dart';

/// This is the configuration of media that will show up as image/video.
class AdMediaConfig with AppodealPlatformArguments {
  AdMediaConfig({
    this.visible = true,
    this.position = AdMediaPosition.top,
    this.margin = 0,
  });

  final bool visible;
  final AdMediaPosition position;
  final int margin;

  @override
  Map<String, dynamic> get toMap =>
      <String, dynamic>{'visible': visible, 'position': position.index, 'margin': margin};
}

enum AdMediaPosition { top, bottom }
