// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';

class GroupAvatar extends HookConsumerWidget {
  const GroupAvatar({
    required this.avatar,
    this.size,
    this.borderRadius,
    super.key,
  });

  final ({String masterPubkey, MediaAttachment? media}) avatar;
  final double? size;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaFuture = useMemoized<Future<File?>>(
      () {
        if (avatar.media == null) {
          return Future<File?>.value();
        }
        return ref
            .read(mediaEncryptionServiceProvider)
            .getEncryptedMedia(
              avatar.media!,
              authorPubkey: avatar.masterPubkey,
            )
            .then((file) => file as File?);
      },
      [avatar.media?.url, avatar.masterPubkey],
    );
    final groupImageFileResult = useFuture(mediaFuture);

    File? groupImageFile;
    if (groupImageFileResult.hasData) {
      final file = groupImageFileResult.data;
      if (file != null && file.existsSync() && file.lengthSync() > 0) {
        groupImageFile = file;
      }
    }

    final avatarSize = size ?? 65.0.s;
    return Avatar(
      size: avatarSize,
      borderRadius: borderRadius ?? BorderRadius.circular(16.0.s),
      imageWidget: groupImageFile != null
          ? Image.file(
              groupImageFile,
              errorBuilder: (context, error, stackTrace) {
                // Show default avatar if image fails to load
                return DefaultAvatar(size: avatarSize);
              },
            )
          : null,
      defaultAvatar: DefaultAvatar(size: avatarSize),
    );
  }
}
