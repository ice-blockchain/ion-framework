// SPDX-License-Identifier: ice License 1.0

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
    final groupImageFile = avatar.media != null
        ? useFuture(
            ref.watch(mediaEncryptionServiceProvider).getEncryptedMedia(
                  avatar.media!,
                  authorPubkey: avatar.masterPubkey,
                ),
          ).data
        : null;

    final avatarSize = size ?? 65.0.s;
    return Avatar(
      size: avatarSize,
      borderRadius: borderRadius ?? BorderRadius.circular(16.0.s),
      imageWidget: groupImageFile != null ? Image.file(groupImageFile) : null,
      defaultAvatar: DefaultAvatar(size: avatarSize),
    );
  }
}
