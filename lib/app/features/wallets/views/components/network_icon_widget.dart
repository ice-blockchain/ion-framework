// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/image_path.dart';

class NetworkIconWidget extends StatelessWidget {
  const NetworkIconWidget({
    required this.imageUrl,
    super.key,
    this.size,
    this.color,
  });

  final String imageUrl;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.0.s;
    final borderRadius = BorderRadius.circular(10.s);
    final colorFilter = color == null
        ? null
        : ColorFilter.mode(
            color!,
            BlendMode.srcIn,
          );

    return imageUrl.isSvg
        ? ClipRRect(
            borderRadius: borderRadius,
            child: SvgPicture.network(
              imageUrl,
              width: iconSize,
              height: iconSize,
              colorFilter: colorFilter,
            ),
          )
        : IonNetworkImage(
            imageUrl: imageUrl,
            width: iconSize,
            height: iconSize,
            imageBuilder: (context, imageProvider) => Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                image: DecorationImage(
                  image: imageProvider,
                  colorFilter: colorFilter,
                ),
              ),
            ),
          );
  }
}
