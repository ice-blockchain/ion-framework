// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/image_path.dart';
import 'package:ion/app/utils/precache_pictures.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletItemIconWidget extends StatelessWidget {
  const WalletItemIconWidget({
    required this.imageUrl,
    required this.type,
    this.color,
    super.key,
  });

  final String imageUrl;
  final WalletItemIconType type;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconSize = type.size;
    final borderRadius = type.borderRadius;
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
              errorBuilder: (_, __, ___) => Assets.svg.walletEmptyicon.icon(size: iconSize),
              placeholderBuilder: (context) {
                return Assets.svg.walletEmptyicon.icon(size: iconSize);
              },
            ),
          )
        : IonNetworkImage(
            imageUrl: imageUrl,
            width: iconSize,
            height: iconSize,
            errorWidget: (_, __, ___) => Assets.svg.walletEmptyicon.icon(size: iconSize),
            borderRadius: borderRadius,
            cacheManager: PreCachePicturesCacheManager.instance,
            imageBuilder: colorFilter != null
                ? (context, imageProvider) => Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        image: DecorationImage(
                          image: imageProvider,
                          colorFilter: colorFilter,
                        ),
                      ),
                    )
                : null,
          );
  }
}
