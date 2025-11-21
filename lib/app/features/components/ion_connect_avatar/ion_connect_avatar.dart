// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_watch_once.dart';

class IonConnectAvatar extends HookConsumerWidget {
  const IonConnectAvatar({
    required this.size,
    required this.masterPubkey,
    this.network = false,
    this.borderRadius,
    this.fit,
    this.shadow,
    super.key,
  });

  final double size;
  final String masterPubkey;
  final BorderRadiusGeometry? borderRadius;
  final BoxFit? fit;
  final BoxShadow? shadow;
  final bool network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnedByCurrentUser = ref.watch(isCurrentUserSelectorProvider(masterPubkey));
    final provider = userPreviewDataProvider(masterPubkey, network: network)
        .select((value) => value.valueOrNull?.data.avatarUrl);

    // Avatar from identity is always the full image and in relay's metadata we're using thumbnails.
    // So taking the first value only to avoid fetching both original image and it's thumbnail.
    final avatarUrl = isOwnedByCurrentUser ? ref.watch(provider) : useWatchOnce(ref, provider);

    final avatar = Avatar(
      imageWidget: avatarUrl != null
          ? IonConnectNetworkImage(
              imageUrl: avatarUrl,
              authorPubkey: masterPubkey,
              height: size,
              width: size,
            )
          : DefaultAvatar(size: size),
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
