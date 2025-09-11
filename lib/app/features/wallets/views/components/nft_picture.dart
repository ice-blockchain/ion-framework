// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/utils/image_path.dart';

class NftPicture extends StatelessWidget {
  const NftPicture({
    required this.imageUrl,
    required this.size,
    this.fit = BoxFit.cover,
    this.borderRadius = 16.0,
    super.key,
  });

  final String imageUrl;
  final Size size;
  final BoxFit fit;
  final double borderRadius;
  @override
  Widget build(BuildContext context) {
    if (imageUrl.isSvg) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.s),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: SvgPicture.network(
            imageUrl,
            width: size.width,
            height: size.height,
            fit: fit,
          ),
        ),
      );
    }
    return IonNetworkImage(
      imageUrl: imageUrl,
      width: size.width,
      height: size.height,
      fit: fit,
      borderRadius: BorderRadius.circular(borderRadius.s),
    );
  }
}
