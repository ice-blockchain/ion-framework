// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

/// A horizontal segment control with an animated sliding indicator (TabBar-style).
/// [labels] define the segments; [selectedIndex] is the current selection;
/// [onSelected] is called when a segment is tapped.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final count = labels.length;
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(4.0.s),
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(14.0.s),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final itemWidth = totalWidth / count;
          final index = selectedIndex.clamp(0, count - 1);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: index * itemWidth,
                width: itemWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.primaryAccent,
                    borderRadius: BorderRadius.circular(12.0.s),
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  count,
                  (i) => _SegmentPill(
                    label: labels[i],
                    selected: i == selectedIndex,
                    onPressed: () => onSelected(i),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textThemes = context.theme.appTextThemes;
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0.s, horizontal: 16.0.s),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: textThemes.body2.copyWith(
                color: selected ? colors.onPrimaryAccent : colors.quaternaryText,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
