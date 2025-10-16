// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/generated/assets.gen.dart';

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    required this.child,
    required this.height,
    super.key,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                Assets.svg.speechBubbleBackground,
                fit: BoxFit.fill,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
