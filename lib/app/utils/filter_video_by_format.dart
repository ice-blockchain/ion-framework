// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

/// Only these formats are supported by Banuba SDK
/// More here:https://docs.banuba.com/ve-pe-sdk/docs/ios/requirements#supported-media-formats
/// And here: https://docs.banuba.com/ve-pe-sdk/docs/android/requirements-ve#supported-media-formats
bool filterVideoByFormat(String mimeType) {
  final format = mimeType.split('/').last;
  if (Platform.isIOS) {
    return format == 'mp4' || format == 'mov' || format == 'm4v';
  }

  return format == 'mp4' || format == 'mov';
}
