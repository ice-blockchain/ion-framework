// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const _longPressDuration = Duration(milliseconds: 300);
const _moveThreshold = 10.0;

// This widget handles long press detection for chart tooltip mode.
// Manages the interaction between scrolling and tooltip display:
// - Normal scrolling: works immediately
// - Tooltip mode: activated after 300ms long press without movement
// - Haptic feedback: triggered when tooltip appears and when moving between data points
class ChartTooltipListener extends HookWidget {
  const ChartTooltipListener({
    required this.canInteract,
    required this.builder,
    super.key,
  });

  final bool canInteract;
  final Widget Function({
    required bool tooltipEnabled,
    required void Function(FlTouchEvent, BaseTouchResponse?) handleChartTouch,
  }) builder;

  @override
  Widget build(BuildContext context) {
    final isTooltipMode = useState(false);
    final previousTouchedSpotIndex = useRef<int?>(null);
    final longPressTimer = useRef<Timer?>(null);
    final pointerDownPosition = useRef<Offset?>(null);

    useEffect(() => () => longPressTimer.value?.cancel(), const []);

    void resetTooltipState([_]) {
      longPressTimer.value?.cancel();
      isTooltipMode.value = false;
      pointerDownPosition.value = null;
      previousTouchedSpotIndex.value = null;
    }

    void activateTooltipMode() {
      isTooltipMode.value = true;
      HapticFeedback.lightImpact();
    }

    void handlePointerDown(PointerDownEvent event) {
      pointerDownPosition.value = event.position;
      longPressTimer.value?.cancel();
      longPressTimer.value = Timer(_longPressDuration, activateTooltipMode);
    }

    void handlePointerMove(PointerMoveEvent event) {
      final startPos = pointerDownPosition.value;
      if (startPos == null || isTooltipMode.value) return;

      final distance = (event.position - startPos).distance;
      if (distance > _moveThreshold) {
        longPressTimer.value?.cancel();
      }
    }

    void handleChartTouch(FlTouchEvent event, BaseTouchResponse? response) {
      if (!isTooltipMode.value) return;

      if ((event is FlLongPressMoveUpdate || event is FlPanUpdateEvent) &&
          response is LineTouchResponse) {
        final spots = response.lineBarSpots;
        if (spots == null || spots.isEmpty) return;

        final currentIndex = spots.first.x.toInt();
        if (previousTouchedSpotIndex.value != currentIndex) {
          previousTouchedSpotIndex.value = currentIndex;
          HapticFeedback.lightImpact();
        }
      }
    }

    final tooltipEnabled = canInteract && isTooltipMode.value;

    return Listener(
      onPointerDown: canInteract ? handlePointerDown : null,
      onPointerMove: handlePointerMove,
      onPointerUp: resetTooltipState,
      onPointerCancel: resetTooltipState,
      child: builder(
        tooltipEnabled: tooltipEnabled,
        handleChartTouch: handleChartTouch,
      ),
    );
  }
}
