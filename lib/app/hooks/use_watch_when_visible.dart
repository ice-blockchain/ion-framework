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

  // Track route path reactively
  final fullPath = useState(router?.state.fullPath);
  final fullPathRef = useRef(router?.state.fullPath);

  // Cache for last value when route is inactive
  final lastValueRef = useRef<T?>(null);

  // Listen to route changes - this will trigger rebuilds when route changes
  useEffect(
    () {
      if (router == null) return null;

      void listener() {
        final newFullPath = router.state.fullPath;
        if (fullPath.value != newFullPath) {
          fullPath.value = newFullPath;
        }
      }

      router.routerDelegate.addListener(listener);
      return () {
        router.routerDelegate.removeListener(listener);
      };
    },
    [router],
  );

  // Calculate if route is active - recalculate on every build
  // Check if:
  // 1. The route path matches (we're on the same route)
  // 2. The route is current (not behind another route)
  // 3. The matched location matches (for tab navigation, this ensures we're on the right tab)
  final currentRoutePath = router?.state.fullPath;
  final currentMatchedLocation = router?.state.matchedLocation;
  final initialMatchedLocation = useRef(router?.state.matchedLocation);
  final isCurrentRoute = context.isCurrentRoute;

  final bool isRouteActive;
  if (router == null) {
    isRouteActive = true;
  } else {
    isRouteActive = fullPathRef.value == currentRoutePath &&
        isCurrentRoute &&
        (initialMatchedLocation.value == currentMatchedLocation ||
            (currentMatchedLocation != null &&
                initialMatchedLocation.value != null &&
                currentMatchedLocation.startsWith(initialMatchedLocation.value!)));
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
