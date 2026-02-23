// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    required this.onRatingChanged,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () => onRatingChanged(starValue),
          icon: starValue <= rating
              ? Assets.svg.iconSolarStar.icon()
              : Assets.svg.iconSolarStarOutline.icon(),
        );
      }),
    );
  }
}
