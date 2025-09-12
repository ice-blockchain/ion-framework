// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

ValueNotifier<List<MediaFile>> useAttachedMediaFilesNotifier(
  WidgetRef ref, {
  required String? attachedMedia,
}) {
  final mediaFiles = useMemoized(
    () {
      if (attachedMedia != null) {
        final decodedList = jsonDecode(attachedMedia) as List<dynamic>;
        return decodedList.map((item) {
          return MediaFile.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
      return <MediaFile>[];
    },
    [attachedMedia],
  );

  return useState<List<MediaFile>>(mediaFiles);
}
