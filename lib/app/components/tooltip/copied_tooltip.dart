// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/shapes/shape.dart';
import 'package:ion/app/components/shapes/triangle_path.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class CopiedTooltip extends HookConsumerWidget {
  const CopiedTooltip({
    required this.onLayout,
    super.key,
  });

  final void Function(Size) onLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tooltipKey = useMemoized(GlobalKey.new);

    useOnInit(() {
      final renderBox = tooltipKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        onLayout(renderBox.size);
      }
    });

    return Column(
      children: [
        Container(
          key: tooltipKey,
          height: 22.0.s,
          padding: EdgeInsets.symmetric(
            horizontal: 6.0.s,
          ),
          decoration: BoxDecoration(
            color: context.theme.appColors.primaryText,
            borderRadius: BorderRadius.circular(8.0.s),
          ),
          alignment: Alignment.center,
          child: Text(
            context.i18n.common_copied,
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.primaryBackground,
            ),
          ),
        ),
        CustomPaint(
          size: Size(7.0.s, 5.0.s),
          painter: ShapePainter(
            const TriangleShapeBuilder(),
            color: context.theme.appColors.primaryText,
          ),
        ),
      ],
    );
  }
}
