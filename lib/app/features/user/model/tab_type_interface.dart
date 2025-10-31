// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

/// Interface for tab types that can be displayed in tab headers
abstract interface class TabType {
  /// Returns the title to display for this tab
  String getTitle(BuildContext context);

  /// Returns the icon asset path for this tab
  String get iconAsset;
}
