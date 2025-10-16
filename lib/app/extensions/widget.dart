// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/services/widget_rebuild_tracker/widget_rebuild_tracker.dart';

extension WidgetRebuildTrackingExtension on Widget {
  /// Tracks this widget's rebuild. Call this at the beginning of your build method.
  ///
  /// Usage:
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   this.trackRebuild(); // Uses widget's runtimeType
  ///   // or with custom name:
  ///   this.trackRebuild('MyWidget-${widget.id}');
  ///
  ///   return YourWidgetContent();
  /// }
  /// ```
  void trackRebuild([String? customName]) {
    final widgetName = customName ?? runtimeType.toString();
    WidgetRebuildTracker.instance.trackRebuild(widgetName);
  }
}

extension ConditionalDecoration on Widget {
  Widget withDecoration(BoxDecoration? decoration) {
    if (decoration != null) return DecoratedBox(decoration: decoration, child: this);
    return this;
  }
}
