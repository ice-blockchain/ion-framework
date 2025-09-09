// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

ValueNotifier<MediaFile?> useAttachedVideo({
  required String? videoPath,
  required String? mimeType,
  required String? videoThumbPath,
}) {
  return useState<MediaFile?>(
    videoPath != null && mimeType != null
        ? MediaFile(
            path: videoPath,
            mimeType: mimeType,
            thumb: videoThumbPath,
          )
        : null,
  );
}
