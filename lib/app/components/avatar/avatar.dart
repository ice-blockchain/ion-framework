// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/avatar/avatar_constants.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/components/shapes/hexagon_path.dart';
import 'package:ion/app/components/shapes/shape.dart';

class Avatar extends StatelessWidget {
  Avatar({
    required this.size,
    super.key,
    this.imageUrl,
    this.badge,
    this.imageWidget,
    BorderRadiusGeometry? borderRadius,
    this.hexagon = false,
    BoxFit? fit,
    this.defaultAvatar,
  })  : borderRadius =
            borderRadius ?? BorderRadius.circular(size * AvatarConstants.borderRadiusRatio),
        fit = fit ?? BoxFit.fitWidth,
        assert(
          imageUrl == null || imageWidget == null,
          'Either imageUrl or imageWidget must be null',
        );

  final double size;
  final BorderRadiusGeometry borderRadius;
  final BoxFit fit;
  final bool hexagon;
  final Widget? badge;
  final String? imageUrl;
  final Widget? imageWidget;
  final Widget? defaultAvatar;
  @override
  Widget build(BuildContext context) {
    final image = imageUrl != null
        ? IonNetworkImage(
            imageUrl: imageUrl!,
            width: size,
            height: size,
            fit: fit,
            errorWidget: (context, url, error) => defaultAvatar ?? DefaultAvatar(size: size),
          )
        : imageWidget != null
            ? SizedBox.square(
                dimension: size,
                child: FittedBox(fit: fit, child: imageWidget),
              )
            : defaultAvatar ?? DefaultAvatar(size: size);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (hexagon)
          ClipPath(
            clipper: ShapeClipper(HexagonShapeBuilder()),
            child: image,
          )
        else
          ClipRRect(borderRadius: borderRadius, child: image),
        if (badge != null) badge!,
      ],
    );
  }
}
