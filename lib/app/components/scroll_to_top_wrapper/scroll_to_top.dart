// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Callback for handle scrolls-to-top event
typedef ScrollsToTopCallback = Future<void> Function(ScrollsToTopEvent event);

/// Event of scrolls-to-top
class ScrollsToTopEvent {
  /// Create new event from [ScrollController.animateTo] arguments
  ScrollsToTopEvent(
    this.to, {
    required this.duration,
    required this.curve,
  });

  /// [to] from [ScrollController.animateTo]
  final double to;

  /// [duration] from [ScrollController.animateTo]
  final Duration duration;

  /// [curve] from [ScrollController.animateTo]
  final Curve curve;

  @override
  String toString() {
    return 'ScrollsToTopEvent{to: $to, duration: $duration, curve: $curve}';
  }
}

/// Widget for catch scrolls-to-top event
class ScrollsToTop extends StatefulWidget {
  /// Creates new ScrollsToTop widget
  const ScrollsToTop({
    required this.child,
    required this.onScrollsToTop,
    super.key,
  });

  /// Any child widget
  final Widget child;

  /// Callback for handle scrolls-to-top event
  final ScrollsToTopCallback onScrollsToTop;

  @override
  State<ScrollsToTop> createState() => _ScrollsToTopState();
}

class _ScrollsToTopState extends State<ScrollsToTop> {
  ScrollController? _primaryScrollController;
  ScrollPositionWithSingleContext? _scrollPositionWithSingleContext;
  bool _attached = false;

  @override
  void dispose() {
    final scrollPositionWithSingleContext = _scrollPositionWithSingleContext;
    if (scrollPositionWithSingleContext != null) {
      _primaryScrollController?.detach(scrollPositionWithSingleContext);
    }
    scrollPositionWithSingleContext?.dispose();
    _scrollPositionWithSingleContext = null;
    _scrollPositionWithSingleContext = null;
    _primaryScrollController = null;
    _attached = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_attached) {
      _attach(context);
      _attached = true;
    }
    return widget.child;
  }

  void _attach(BuildContext context) {
    final primaryScrollController =
        PrimaryScrollController.maybeOf(Navigator.of(context).context) ??
            PrimaryScrollController.maybeOf(context);
    if (primaryScrollController == null) return;

    final scrollPositionWithSingleContext = _FakeScrollPositionWithSingleContext(
      context: context,
      callback: widget.onScrollsToTop,
    );
    primaryScrollController.attach(scrollPositionWithSingleContext);

    _primaryScrollController = primaryScrollController;
    _scrollPositionWithSingleContext = scrollPositionWithSingleContext;
  }
}

class _FakeScrollPositionWithSingleContext extends ScrollPositionWithSingleContext {
  _FakeScrollPositionWithSingleContext({
    required BuildContext context,
    required ScrollsToTopCallback callback,
  })  : _callback = callback,
        super(
          physics: const NeverScrollableScrollPhysics(),
          context: _FakeScrollContext(context),
        );

  final ScrollsToTopCallback _callback;

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    return _callback(
      ScrollsToTopEvent(to, duration: duration, curve: curve),
    );
  }
}

class _FakeScrollContext extends ScrollContext {
  _FakeScrollContext(this._context);

  final BuildContext _context;

  @override
  AxisDirection get axisDirection => AxisDirection.down;

  @override
  BuildContext get notificationContext => _context;

  @override
  void saveOffset(double offset) {}

  @override
  void setCanDrag(bool value) {}

  @override
  void setIgnorePointer(bool value) {}

  @override
  void setSemanticsActions(Set<SemanticsAction> actions) {}

  @override
  BuildContext get storageContext => _context;

  @override
  TickerProvider get vsync => _FakeTickerProvider();

  @override
  double get devicePixelRatio => MediaQuery.of(_context).devicePixelRatio;
}

class _FakeTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
