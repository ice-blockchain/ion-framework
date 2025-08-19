// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/services/media_service/aspect_ratio.dart';

class StoryImagePreview extends StatelessWidget {
  const StoryImagePreview({
    required this.path,
    super.key,
  });

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0.s),
      child: AspectRatio(
        aspectRatio: MediaAspectRatio.portrait,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          width: 600.0.s,
          height: 600.0.s,
        ),
      ),
    );
  }
}
