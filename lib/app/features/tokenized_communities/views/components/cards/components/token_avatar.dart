// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class TokenAvatar extends HookWidget {
  const TokenAvatar({
    required this.imageUrl,
    required this.containerSize,
    required this.imageSize,
    required this.outerBorderRadius,
    required this.innerBorderRadius,
    required this.borderWidth,
    this.borderColor,
    this.enablePaletteGenerator = true,
    super.key,
  });

  final String? imageUrl;
  final Size containerSize;
  final Size imageSize;

  final double outerBorderRadius;
  final double innerBorderRadius;
  final double borderWidth;

  final Color? borderColor;
  final bool enablePaletteGenerator;

  @override
  Widget build(BuildContext context) {
    final imageColors = useImageColors(imageUrl, enabled: enablePaletteGenerator);

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
              if (imageUrl == null || imageUrl!.isEmpty) {
                return DefaultAvatar(size: imageSize.width);
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
                    errorBuilder: (context, url, error) => DefaultAvatar(size: imageSize.width),
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
