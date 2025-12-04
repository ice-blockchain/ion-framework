// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/image_path.dart';

class CommunityTokenImage extends HookWidget {
  const CommunityTokenImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.outerBorderRadius,
    this.innerBorderRadius,
    this.innerPadding,
    this.borderWidth,
    super.key,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final double? outerBorderRadius;
  final double? innerBorderRadius;
  final double? borderWidth;
  final double? innerPadding;

  @override
  Widget build(BuildContext context) {
    final width = this.width ?? 94.s;
    final height = this.height ?? 94.s;
    final outerBorderRadius = this.outerBorderRadius ?? 24.s;
    final innerBorderRadius = this.innerBorderRadius ?? 24.s;
    final borderWidth = this.borderWidth ?? 1.7.s;
    final innerPadding = this.innerPadding ?? 3.s;

    final imageColors = useImageColors(imageUrl);

    final gradient = useMemoized(
      () {
        return imageColors != null
            ? SweepGradient(
                colors: [
                  imageColors.second,
                  imageColors.first,
                ],
              )
            : storyBorderGradients[random.nextInt(storyBorderGradients.length)];
      },
      [imageColors],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerBorderRadius),
          // GradientBoxBorder not accepting AlignmentDirectional
          border: GradientBoxBorder(
            gradient: LinearGradient(
              // ignore: prefer_alignment_directional
              begin: Alignment.topLeft,
              // ignore: prefer_alignment_directional
              end: Alignment.bottomRight,
              colors: gradient.colors,
              stops: gradient.stops,
            ),
            width: borderWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(innerPadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(innerBorderRadius),
            child: Builder(
              builder: (context) {
                if (imageUrl == null) {
                  return const SizedBox.shrink();
                }
                if (imageUrl!.isSvg) {
                  return SvgPicture.network(
                    imageUrl!,
                    width: width,
                    height: height,
                    errorBuilder: (context, url, error) => Container(),
                  );
                }

                return IonNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: width,
                  height: height,
                  errorWidget: (context, url, error) => Container(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
