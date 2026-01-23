// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/build_context.dart';

/// Hook that watches a provider only when the route is active.
///
/// When the route is not active (navigated away or behind another route),
/// returns the last known value. This prevents unnecessary provider subscriptions
/// when the route is not visible.
///
/// The provider will be disposed (and its subscription closed) when not watched,
/// and recreated when the route becomes active again.
///
/// Example:
/// ```dart
/// final tokenInfo = useWatchWhenVisible(
///   watcher: () => ref.watch(tokenMarketInfoProvider(externalAddress)),
/// );
/// ```
T useWatchWhenVisible<T>({
  required T Function() watcher,
}) {
  final context = useContext();
  final router = GoRouter.maybeOf(context);

  // Track initial route path (captured when hook is created)
  final fullPathRef = useRef(router?.state.fullPath);

  // Track isCurrentRoute in state to only rebuild when it changes
  final isCurrentRouteState = useState(context.isCurrentRoute);
  final isCurrentRouteRef = useRef(context.isCurrentRoute);

  // Track matched location
  final matchedLocation = useState(router?.state.matchedLocation);
  final initialMatchedLocation = useRef(router?.state.matchedLocation);

  // Cache for last value when route is inactive
  final lastValueRef = useRef<T?>(null);

  // Listen to route changes - this will trigger rebuilds when route changes
  useEffect(
    () {
      if (router == null) return null;

      void listener() {
        final newMatchedLocation = router.state.matchedLocation;
        if (matchedLocation.value != newMatchedLocation) {
          matchedLocation.value = newMatchedLocation;
        }
      }

      router.routerDelegate.addListener(listener);
      return () {
        router.routerDelegate.removeListener(listener);
      };
    },
    [router],
  );

  // Check if isCurrentRoute changed and update state only when necessary
  // Check synchronously during build, use current value for calculation
  final currentIsCurrentRoute = context.isCurrentRoute;

  // Update state only when value changes (triggers rebuild for next build cycle)
  useEffect(
    () {
      if (isCurrentRouteRef.value != currentIsCurrentRoute) {
        isCurrentRouteRef.value = currentIsCurrentRoute;
        if (isCurrentRouteState.value != currentIsCurrentRoute) {
          isCurrentRouteState.value = currentIsCurrentRoute;
        }
      }
      return null;
    },
    [currentIsCurrentRoute],
  );

  // Use current value for calculation (most up-to-date), state will be updated for next cycle
  final isCurrentRouteForCalculation = currentIsCurrentRoute;

  // Calculate if route is active - only recalculates when tracked values change
  final bool isRouteActive;
  if (router == null) {
    isRouteActive = true;
  } else {
    final currentRoutePath = router.state.fullPath;
    isRouteActive = fullPathRef.value == currentRoutePath &&
        isCurrentRouteForCalculation &&
        (initialMatchedLocation.value == matchedLocation.value ||
            (matchedLocation.value != null &&
                initialMatchedLocation.value != null &&
                matchedLocation.value!.startsWith(initialMatchedLocation.value!)));
  }

  // Conditionally watch provider based on route activation
  // Only call watcher when route is active to prevent watching when inactive
  T? currentValue;
  if (isRouteActive) {
    // Watch when active - keeps provider alive and subscription active
    currentValue = watcher();
    // Update cache with latest value
    lastValueRef.value = currentValue;
  } else {
    // Route is inactive - use cached value (don't call watcher)
    currentValue = lastValueRef.value;
  }

  // Return current value when route is active, cached value when inactive
  return currentValue as T;
}
