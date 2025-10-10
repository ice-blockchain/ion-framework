// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_request_sheet.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/settings_redirect_sheet.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/generated/assets.gen.dart';

class ChatInputBarCameraButton extends ConsumerWidget {
  const ChatInputBarCameraButton({required this.onSubmitted, super.key});

  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionAwareWidget(
      permissionType: Permission.photos,
      onGranted: () async {
        final mediaFiles = await MediaPickerRoute(
          maxSelection: 10,
          isNeedFilterVideoByFormat: false,
          maxVideoDurationInSeconds:
              ReplaceablePrivateDirectMessageData.videoDurationLimitInSeconds,
        ).push<List<MediaFile>>(context);
        if (mediaFiles != null && mediaFiles.isNotEmpty && context.mounted) {
          final convertedMediaFiles = await ref
              .read(mediaServiceProvider)
              .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);

          unawaited(onSubmitted(mediaFiles: convertedMediaFiles));
        }
      },
      requestDialog: const PermissionRequestSheet(permission: Permission.photos),
      settingsDialog: SettingsRedirectSheet.fromType(context, Permission.photos),
      builder: (_, onPressed) => GestureDetector(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(10.0.s, 4.0.s, 0, 4.0.s),
          child: Assets.svg.iconCameraOpen.icon(
            color: context.theme.appColors.primaryText,
            size: 24.0.s,
          ),
        ),
      ),
    );
  }
}
