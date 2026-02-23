// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/services/logger/logger.dart';

/// Prevents crashes caused by null route animations during sheet drag gestures.
class SafeHeroController extends HeroController {
  SafeHeroController()
      : super(
          createRectTween: (Rect? begin, Rect? end) {
            return MaterialRectArcTween(begin: begin, end: end);
          },
        );

  static bool _isNullAnimationTypeError(Object error) {
    return error is TypeError &&
        error.toString().contains('Null check operator used on a null value');
  }

  static bool _hasNullRouteAnimation(Route<dynamic>? route) {
    return route is PageRoute<dynamic> && route.animation == null;
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    if (_hasNullRouteAnimation(route) || _hasNullRouteAnimation(previousRoute)) {
      Logger.warning(
        'Skipped hero transition for a swipe dismiss gesture due to null '
        'route animation.',
      );
      return;
    }

    try {
      super.didStartUserGesture(route, previousRoute);
    } catch (error) {
      if (!_isNullAnimationTypeError(error)) {
        rethrow;
      }
      Logger.warning(
        'Ignored hero transition crash during a modal swipe dismiss gesture.',
      );
    }
  }

  @override
  void didStopUserGesture() {
    try {
      super.didStopUserGesture();
    } catch (error) {
      if (!_isNullAnimationTypeError(error)) {
        rethrow;
      }
      Logger.warning(
        'Ignored hero transition crash when finishing a swipe dismiss gesture.',
      );
    }
  }
}
