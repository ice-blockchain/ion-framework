// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/nsfw_validation_service.r.dart';
import 'package:ion/app/features/nsfw/widgets/nsfw_blocked_sheet.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class NsfwSubmitGuard {
  const NsfwSubmitGuard._();

  static Future<bool> checkAndBlockMediaFiles(
    WidgetRef ref,
    List<MediaFile> mediaFiles,
  ) async {
    return _checkAndBlock(
      ref.context,
      () => ref.read(nsfwValidationServiceProvider).hasNsfwInMediaFiles(mediaFiles),
    );
  }

  static Future<bool> checkAndBlockImagePaths(
    WidgetRef ref,
    List<String> imagePaths,
  ) async {
    return _checkAndBlock(
      ref.context,
      () => ref.read(nsfwValidationServiceProvider).hasNsfwInImagePaths(imagePaths),
    );
  }

  static Future<bool> _checkAndBlock(
    BuildContext context,
    Future<bool> Function() check,
  ) async {
    try {
      final hasNsfw = await check();
      if (hasNsfw) {
        if (context.mounted) {
          await showNsfwBlockedSheet(context);
        }
        return true;
      }
    } catch (e) {
      Logger.error(e, message: 'NSFW validation failed');
    }
    return false;
  }
}
