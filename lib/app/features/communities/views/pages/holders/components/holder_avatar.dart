import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/image_path.dart';
import 'package:ion/generated/assets.gen.dart';

class HolderAvatar extends StatelessWidget {
  const HolderAvatar({super.key, this.imageUrl});
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final emptyIcon = Container(
      width: 30.0.s,
      height: 30.0.s,
      padding: EdgeInsets.all(4.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.onTertiaryFill,
        borderRadius: BorderRadius.circular(10.0.s),
      ),
      child: Assets.svg.iconProfileNoimage.icon(size: 12.0.s),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return emptyIcon;
    }

    if (imageUrl!.isSvg) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0.s),
        child: SvgPicture.network(
          imageUrl!,
          width: 30.0.s,
          height: 30.0.s,
          errorBuilder: (context, url, error) => emptyIcon,
        ),
      );
    }

    return IonNetworkImage(
      borderRadius: BorderRadius.circular(10.0.s),
      imageUrl: imageUrl!,
      width: 30.0.s,
      height: 30.0.s,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => emptyIcon,
    );
  }
}
