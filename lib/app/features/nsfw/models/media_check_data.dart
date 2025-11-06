// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/media_service/media_service.m.dart';

class MediaCheckData {
  const MediaCheckData({
    required this.mediaFile,
    required this.completer,
  });

  final MediaFile mediaFile;
  final Completer<bool> completer;
}
