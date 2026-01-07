// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/avatar.dart';
import 'package:ion/app/utils/image_path.dart';

class HolderAvatar extends HookWidget {
  const HolderAvatar({
    super.key,
    this.imageUrl,
    this.seed,
    this.isXUser = false,
  });

  final String? imageUrl;
  final String? seed;
  final bool isXUser;

  @override
  Widget build(BuildContext context) {
    final size = 30.0.s;
    final borderRadius = BorderRadius.circular(10.0.s);
    final emptyIcon = useMemoized(
      () => ClipRRect(
        borderRadius: borderRadius,
        child: isXUser ? getRandomDefaultAvatar(seed).icon(size: size) : DefaultAvatar(size: size),
      ),
      [seed],
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return emptyIcon;
    }

    if (imageUrl!.isSvg) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageUrl!.isNetworkSvg
            ? SvgPicture.network(
                imageUrl!,
                width: size,
                height: size,
                errorBuilder: (context, url, error) => emptyIcon,
              )
            : imageUrl!.icon(size: size),
      );
    }

    return IonNetworkImage(
      borderRadius: borderRadius,
      imageUrl: imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => emptyIcon,
    );
  }
}
