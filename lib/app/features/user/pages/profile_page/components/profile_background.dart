// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class ProfileBackground extends StatelessWidget {
  const ProfileBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: context.theme.appColors.primaryText),
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            child: Opacity(
              opacity: 0.40,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.50, 0.20),
                    radius: 0.77,
                    colors: [Color(0xFF115DC9), Color(0x003F6EDC)],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 37.s,
            top: 23.s,
            child: Opacity(
              opacity: 0.50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 600, sigmaY: 600),
                child: Container(
                  width: 300.s,
                  height: 208.s,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF115ECA),
                    shape: OvalBorder(),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 328.05.s,
            top: -425.s,
            child: Opacity(
              opacity: 0.65,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 600, sigmaY: 600),
                child: Container(
                  transform: Matrix4.identity()..rotateZ(0.69),
                  width: 675.85,
                  height: 468.74,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFB601BF),
                    shape: OvalBorder(),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: -244.77.s,
            top: -387.52.s,
            child: Opacity(
              opacity: 0.55,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 600,
                  sigmaY: 600,
                ),
                child: Container(
                  transform: Matrix4.identity()..rotateZ(0.69),
                  width: 611.43.s,
                  height: 424.06.s,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF02ACCA),
                    shape: OvalBorder(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
