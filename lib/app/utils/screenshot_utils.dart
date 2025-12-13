// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

/// Captures a screenshot of a widget and saves it to a temporary file
///
/// Returns a [File] with the screenshot image or null if capture failed
Future<File?> captureWidgetScreenshot({
  required BuildContext context,
  required Widget widget,
  double pixelRatio = 3.0,
  Duration delay = const Duration(milliseconds: 300),
  double? width,
  double? height,
}) async {
  try {
    final screenshotController = ScreenshotController();

    var widgetToCapture = widget;
    var mediaQueryData = MediaQuery.of(context);

    if (width != null && height != null) {
      mediaQueryData = mediaQueryData.copyWith(size: Size(width, height));
      widgetToCapture = SizedBox(width: width, height: height, child: widget);
    }

    final imageBytes = await screenshotController.captureFromWidget(
      Localizations.override(
        context: context,
        locale: Localizations.localeOf(context),
        child: MediaQuery(
          data: mediaQueryData,
          child: Directionality(
            textDirection: Directionality.of(context),
            child: InheritedTheme.captureAll(context, widgetToCapture),
          ),
        ),
      ),
      pixelRatio: pixelRatio,
      delay: delay,
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(imageBytes);

    return tempFile;
  } catch (e, st) {
    Logger.error('Error capturing widget screenshot:', stackTrace: st);
    return null;
  }
}
