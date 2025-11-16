// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

typedef FilterVideoMimeTypeExtractor<T> = String? Function(T mediaFile);

/// Only these formats are supported by Banuba SDK
/// More here:https://docs.banuba.com/ve-pe-sdk/docs/ios/requirements#supported-media-formats
/// And here: https://docs.banuba.com/ve-pe-sdk/docs/android/requirements-ve#supported-media-formats
List<T> filterUnsupportedVideoFormats<T>(
  List<T> mediaFiles, {
  required bool isNeedFilterVideoByFormat,
  required FilterVideoMimeTypeExtractor<T> filterVideoMimeTypeExtractor,
}) {
  if (!isNeedFilterVideoByFormat) {
    return mediaFiles;
  }

  final filteredMediaFiles = <T>[];
  for (final mediaFile in mediaFiles) {
    final mimeType = filterVideoMimeTypeExtractor(mediaFile);
    if (mimeType?.startsWith('video/') ?? false) {
      if (!_filterVideoByFormat(mimeType!)) {
        continue;
      }
    }

    filteredMediaFiles.add(mediaFile);
  }

  return filteredMediaFiles;
}

bool _filterVideoByFormat(String mimeType) {
  final format = mimeType.split('/').last;
  if (Platform.isIOS) {
    return format == 'mp4' || format == 'mov' || format == 'm4v' || format == 'quicktime';
  }

  return format == 'mp4' || format == 'mov';
}
