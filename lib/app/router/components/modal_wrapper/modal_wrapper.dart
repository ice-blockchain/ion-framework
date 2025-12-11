// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class ModalWrapper extends StatelessWidget {
  const ModalWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && Navigator.of(context).canPop() && context.mounted) {
          context.pop();
        }
      },
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return PagedSheet(
            navigator: child,
            physics: isKeyboardVisible ? const _LockedSheetPhysics() : const ClampingSheetPhysics(),
          );
        },
      ),
    );
  }
}

class _LockedSheetPhysics extends SheetPhysics {
  const _LockedSheetPhysics();

  @override
  double computeOverflow(double delta, SheetMetrics metrics) => delta;

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) => 0;

  @override
  Simulation? createBallisticSimulation(
    double velocity,
    SheetMetrics metrics,
    SheetSnapGrid snapGrid,
  ) =>
      null;
}
