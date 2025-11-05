// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';

/// Interface for tab types used in tabs headers
/// Implemented by enums like [UserContentType] and [GroupAdminTab]
abstract interface class TabType {
  /// Returns the icon asset path for this tab type
  String get iconAsset;

  /// Returns the localized title for this tab type
  String getTitle(BuildContext context);
}
