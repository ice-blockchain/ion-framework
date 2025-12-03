// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    required this.rating,
    super.key,
    this.starCount = 5,
    this.size = 18,
    this.color = Colors.amber,
  });

  final double rating;
  final int starCount;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        if (index >= rating) {
          // Empty star
          return Icon(Icons.star_border_rounded, color: color, size: size);
        } else if (index > rating - 1 && index < rating) {
          // Half star
          return Icon(Icons.star_half_rounded, color: color, size: size);
        } else {
          // Full star
          return Icon(Icons.star_rounded, color: color, size: size);
        }
      }),
    );
  }
}
