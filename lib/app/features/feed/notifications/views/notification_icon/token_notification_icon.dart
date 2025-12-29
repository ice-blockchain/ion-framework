import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenNotificationIcon extends StatelessWidget {
  const TokenNotificationIcon({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ButtonIconFrame(
      containerSize: size,
      borderRadius: BorderRadius.circular(10.0.s),
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          context.theme.appColors.electricViolet,
          context.theme.appColors.electricViolet,
          context.theme.appColors.heliotrope,
        ],
        stops: const [
          0.1074,
          0.5148,
          1.0,
        ],
      ),
      icon: Assets.svg.iconMessageMeme2.icon(
        size: 16.s,
      ),
    );
  }
}
