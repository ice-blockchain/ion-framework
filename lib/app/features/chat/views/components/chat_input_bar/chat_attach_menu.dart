// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/model/upload_limit_modal_type.dart';
import 'package:ion/app/features/chat/views/pages/upload_limit_reached_modal/upload_limit_reached_modal.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_aware_widget.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/permission_request_sheet.dart';
import 'package:ion/app/features/core/permissions/views/components/permission_dialogs/settings_redirect_sheet.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/media_service/video_info_service.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:mime/mime.dart';

class ChatAttachMenu extends ConsumerWidget {
  const ChatAttachMenu({
    required this.onSubmitted,
    this.receiverPubKey,
    super.key,
  });

  static const double moreContentHeight = 206;

  final String? receiverPubKey;
  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 20.s),
      child: StaggeredGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 30.s,
        crossAxisSpacing: 30.s,
        children: [
          _MediaButton(onSubmitted: onSubmitted),
          _CameraButton(onSubmitted: onSubmitted),
          _IonPayButton(receiverMasterPubkey: receiverPubKey),
          _ProfileShareButton(onSubmitted: onSubmitted),
          _DocumentButton(onSubmitted: onSubmitted),
        ],
      ),
    );
  }
}

class _MediaButton extends ConsumerWidget {
  const _MediaButton({
    required this.onSubmitted,
  });
  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionAwareWidget(
      permissionType: Permission.photos,
      onGranted: () async {
        final mediaFiles = await MediaPickerRoute(
          maxSelection: 10,
          isNeedFilterVideoByFormat: false,
          maxVideoDurationInSeconds: EncryptedDirectMessageData.videoDurationLimitInSeconds,
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
    );
  }
}

class _CameraButton extends ConsumerWidget {
  const _CameraButton({
    required this.onSubmitted,
  });
  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionAwareWidget(
      permissionType: Permission.photos,
      onGranted: () async {
        final mediaFiles = await MediaPickerRoute(
          maxSelection: 10,
          isNeedFilterVideoByFormat: false,
          maxVideoDurationInSeconds: EncryptedDirectMessageData.videoDurationLimitInSeconds,
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
    );
  }
}

class _IonPayButton extends ConsumerWidget {
  const _IonPayButton({required this.receiverMasterPubkey});
  final String? receiverMasterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (receiverMasterPubkey == null) {
      return const SizedBox.shrink();
    }
    return _MoreContentItem(
      iconPath: Assets.svg.walletChatIonpay,
      title: context.i18n.common_ion_pay,
      onTap: () async {
        final needToEnable2FA =
            await PaymentSelectionChatRoute(pubkey: receiverMasterPubkey!).push<bool>(context);
        if (needToEnable2FA != null && needToEnable2FA == true && context.mounted) {
          await SecureAccountModalRoute().push<void>(context);
        }
      },
    );
  }
}

class _ProfileShareButton extends ConsumerWidget {
  const _ProfileShareButton({
    required this.onSubmitted,
  });
  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MoreContentItem(
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
    );
  }
}

class _DocumentButton extends ConsumerWidget {
  const _DocumentButton({
    required this.onSubmitted,
  });
  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MoreContentItem(
      iconPath: Assets.svg.walletChatDocument,
      title: context.i18n.common_document,
      onTap: () async {
        final filePickerResult = await FilePicker.platform.pickFiles(
          allowCompression: false,
        );
        final file = filePickerResult?.files.first;
        if (file != null && file.path != null) {
          final mimeType = lookupMimeType(file.path!);
          final mediaType = MediaType.fromMimeType(mimeType ?? '');
          var mediaFile = MediaFile(
            name: file.name,
            path: file.path!,
            mimeType: mimeType,
            width: file.size,
            height: file.size,
          );

          if (mediaType == MediaType.unknown) {
            if (file.size > EncryptedDirectMessageData.fileMessageSizeLimit) {
              if (context.mounted) {
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
            }
          } else if (mediaType == MediaType.video) {
            final duration =
                (await ref.read(videoInfoServiceProvider).getVideoInformation(file.path!)).duration;
            if (duration.inSeconds > EncryptedDirectMessageData.videoDurationLimitInSeconds) {
              if (context.mounted) {
                unawaited(
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => const UploadLimitReachedModal(
                      type: UploadLimitModalType.video,
                    ),
                  ),
                );
                return;
              }
            }
            mediaFile = mediaFile.copyWith(
              duration: duration.inSeconds,
            );
          }

          unawaited(onSubmitted(mediaFiles: [mediaFile]));
        }
      },
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          iconPath.iconWithDimensions(
            height: 48.0.s,
          ),
          SizedBox(height: 6.0.s),
          Text(
            title,
            style: context.theme.appTextThemes.body2,
          ),
        ],
      ),
    );
  }
}
