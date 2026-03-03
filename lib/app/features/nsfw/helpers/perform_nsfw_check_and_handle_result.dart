// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/views/pages/error_modal.dart';
import 'package:ion/app/features/nsfw/models/nsfw_check_result.f.dart';
import 'package:ion/app/features/nsfw/providers/media_nsfw_checker.r.dart';
import 'package:ion/app/features/nsfw/widgets/nsfw_blocked_sheet.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

/// Runs NSFW check via [MediaNsfwChecker] and handles the result (error modal
/// or blocked sheet). Returns true if the user can proceed, false if blocked
/// or on error.
Future<bool> performNsfwCheckAndHandleResult(
  WidgetRef ref, {
  required List<MediaFile> mediaFiles,
}) async {
  final mediaChecker = await ref.read(mediaNsfwCheckerProvider.future);
  await mediaChecker.checkMediaForNsfw(mediaFiles);
  final nsfwCheckResult = await mediaChecker.hasNsfwMedia();

  final context = ref.context;
  if (!context.mounted) return false;

  if (nsfwCheckResult is NsfwFailure) {
    showErrorModal(context, NSFWProcessingException());
    return false;
  }
  if (nsfwCheckResult is NsfwSuccess && nsfwCheckResult.hasNsfw) {
    if (context.mounted) {
      await showNsfwBlockedSheet(context);
    }
    return false;
  }
  return true;
}
