// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/services/media_service/aspect_ratio.dart';

class PostScreenshotPreview extends StatelessWidget {
  const PostScreenshotPreview({
    required this.path,
    this.eventReference,
    super.key,
  });

  final String path;
  final EventReference? eventReference;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final isProfileReference = eventReference?.isProfileReference ?? false;
    final isCommunityTokenReference = eventReference?.isCommunityTokenReference ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0.s),
      child: AspectRatio(
        aspectRatio: MediaAspectRatio.portrait,
        child: isProfileReference || isCommunityTokenReference
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16.0.s),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : ColoredBox(
                color: colors.attentionBlock,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0.s),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0.s),
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
