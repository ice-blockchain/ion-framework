// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

class IonConnectAvatar extends ConsumerWidget {
  const IonConnectAvatar({
    required this.pubkey,
    required this.size,
    this.borderRadius,
    this.fit,
    this.shadow,
    super.key,
  });

  final String pubkey;
  final double size;
  final BorderRadiusGeometry? borderRadius;
  final BoxFit? fit;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataSyncProvider(pubkey));

    final avatar = Avatar(
      imageWidget: userMetadata != null
          ? userMetadata.data.avatarUrl != null
              ? IonConnectNetworkImage(
                  imageUrl: userMetadata.data.avatarUrl!,
                  authorPubkey: pubkey,
                  height: size,
                  width: size,
                )
              : DefaultAvatar(size: size)
          : const SizedBox.shrink(),
      size: size,
      borderRadius: borderRadius,
      fit: fit,
    );

    if (shadow != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(size * 0.3),
          boxShadow: [shadow!],
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}
