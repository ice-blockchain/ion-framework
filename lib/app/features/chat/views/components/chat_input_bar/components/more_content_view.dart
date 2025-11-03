// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/model/upload_limit_modal_type.dart';
import 'package:ion/app/features/chat/views/pages/upload_limit_reached_modal/upload_limit_reached_modal.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_request_sheet.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/settings_redirect_sheet.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:mime/mime.dart';

final double moreContentHeight = 206.0.s;

class MoreContentView extends ConsumerWidget {
  const MoreContentView({
    required this.onSubmitted,
    this.receiverPubKey,
    super.key,
  });

  final String? receiverPubKey;
  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: context.theme.appColors.secondaryBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PermissionAwareWidget(
                permissionType: Permission.photos,
                onGranted: () async {
                  final mediaFiles = await MediaPickerRoute(
                    isNeedFilterVideoByFormat: false,
                    maxSelection: 10,
                    maxVideoDurationInSeconds:
                        EncryptedDirectMessageData.videoDurationLimitInSeconds,
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
                builder: (context, onPressed) => _MoreContentItem(
                  iconPath: Assets.svg.walletChatPhotos,
                  title: context.i18n.common_media,
                  onTap: onPressed,
                ),
              ),
              PermissionAwareWidget(
                permissionType: Permission.photos,
                onGranted: () async {
                  final mediaFiles = await MediaPickerRoute(
                    isNeedFilterVideoByFormat: false,
                    maxSelection: 10,
                    maxVideoDurationInSeconds:
                        EncryptedDirectMessageData.videoDurationLimitInSeconds,
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
                builder: (context, onPressed) => _MoreContentItem(
                  iconPath: Assets.svg.walletChatCamera,
                  title: context.i18n.common_camera,
                  onTap: onPressed,
                ),
              ),
              _MoreContentItem(
                iconPath: Assets.svg.walletChatIonpay,
                title: context.i18n.common_ion_pay,
                onTap: () async {
                  if (receiverPubKey == null) {
                    return;
                  }
                  final needToEnable2FA =
                      await PaymentSelectionChatRoute(pubkey: receiverPubKey!).push<bool>(context);
                  if (needToEnable2FA != null && needToEnable2FA == true && context.mounted) {
                    await SecureAccountModalRoute().push<void>(context);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 30.0.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MoreContentItem(
                iconPath: Assets.svg.walletChatPerson,
                title: context.i18n.common_profile,
                onTap: () async {
                  final selectedProfilePubkey = await SendProfileModalRoute().push<String>(context);
                  if (selectedProfilePubkey != null) {
                    final eventReference = ReplaceableEventReference(
                      masterPubkey: selectedProfilePubkey,
                      kind: UserMetadataEntity.kind,
                    );

                    unawaited(onSubmitted(content: eventReference.encode()));
                  }
                },
              ),
              _MoreContentItem(
                iconPath: Assets.svg.walletChatDocument,
                title: context.i18n.common_document,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowCompression: false,
                  );
                  final firstFile = result?.files.first;
                  if (firstFile != null && context.mounted && firstFile.path != null) {
                    final mimeType = lookupMimeType(firstFile.path!);
                    if (firstFile.size > EncryptedDirectMessageData.fileMessageSizeLimit) {
                      unawaited(
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => const UploadLimitReachedModal(
                            type: UploadLimitModalType.file,
                          ),
                        ),
                      );
                      return;
                    }

                    unawaited(
                      onSubmitted(
                        content: firstFile.name,
                        mediaFiles: [
                          MediaFile(
                            path: firstFile.path!,
                            mimeType: mimeType,
                            width: firstFile.size,
                            height: firstFile.size,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              SizedBox(width: 48.0.s),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreContentItem extends StatelessWidget {
  const _MoreContentItem({
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  final String iconPath;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          iconPath.icon(
            size: 48.0.s,
          ),
          SizedBox(width: 8.0.s),
          Text(
            title,
            style: context.theme.appTextThemes.body2,
          ),
        ],
      ),
    );
  }
}
