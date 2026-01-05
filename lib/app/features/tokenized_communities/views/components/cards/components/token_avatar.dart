// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenAvatar extends HookWidget {
  const TokenAvatar({
    required this.imageUrl,
    required this.containerSize,
    required this.imageSize,
    required this.outerBorderRadius,
    required this.innerBorderRadius,
    required this.borderWidth,
    this.borderColor,
    super.key,
  });

  final String? imageUrl;
  final Size containerSize;
  final Size imageSize;

  final double outerBorderRadius;
  final double innerBorderRadius;
  final double borderWidth;

  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
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

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        SizedBox(
          width: containerSize.width,
          height: containerSize.height,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(outerBorderRadius),
              // GradientBoxBorder not accepting AlignmentDirectional
              border: borderWidth > 0
                  ? borderColor != null
                      ? Border.all(color: borderColor!, width: borderWidth)
                      : GradientBoxBorder(
                          gradient: LinearGradient(
                            // ignore: prefer_alignment_directional
                            begin: Alignment.topLeft,
                            // ignore: prefer_alignment_directional
                            end: Alignment.bottomRight,
                            colors: gradient.colors,
                            stops: gradient.stops,
                          ),
                          width: borderWidth,
                        )
                  : null,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(innerBorderRadius),
          child: Builder(
            builder: (context) {
              if (imageUrl == null) {
                return _NoImage(
                  size: imageSize.width,
                  innerBorderRadius: innerBorderRadius,
                );
              }
              return IonNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: imageSize.width,
                height: imageSize.height,
                errorWidget: (context, url, error) {
                  return SvgPicture.network(
                    imageUrl!,
                    width: imageSize.width,
                    height: imageSize.height,
                    errorBuilder: (context, url, error) => _NoImage(
                      size: imageSize.width,
                      innerBorderRadius: innerBorderRadius,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoImage extends StatelessWidget {
  const _NoImage({
    required this.size,
    required this.innerBorderRadius,
  });

  final double size;
  final double innerBorderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(innerBorderRadius),
      child: Container(
        width: size,
        height: size,
        alignment: AlignmentDirectional.center,
        color: context.theme.appColors.onTertiaryFill,
        child: Assets.svg.iconProfileNoimage.icon(
          size: size * 0.9,
        ),
      ),
    );
  }
}
