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

  final matchedLocationRef = useRef(router?.state.matchedLocation);
  final initialMatchedLocation = useRef(router?.state.matchedLocation);

  final lastValueRef = useRef<T?>(null);

  final isRouteActiveState = useState<bool>(true);

  useEffect(
    () {
      if (router == null) return null;

      void listener() {
        final newMatchedLocation = router.state.matchedLocation;
        final currentRoutePath = router.state.fullPath;
        final isCurrentRoute = context.isCurrentRoute;

        matchedLocationRef.value = newMatchedLocation;

        // Calculate new route active status
        final newIsRouteActive = fullPathRef.value == currentRoutePath &&
            isCurrentRoute &&
            (initialMatchedLocation.value == newMatchedLocation ||
                (initialMatchedLocation.value != null &&
                    newMatchedLocation.startsWith(initialMatchedLocation.value!)));

        // Only update state (trigger rebuild) when route activation status actually changes
        if (isRouteActiveState.value != newIsRouteActive) {
          isRouteActiveState.value = newIsRouteActive;
        }
      }

      router.routerDelegate.addListener(listener);
      return () {
        router.routerDelegate.removeListener(listener);
      };
    },
    [router],
  );

  // Conditionally watch provider based on route activation
  // Only call watcher when route is active to prevent watching when inactive
  T? currentValue;
  if (isRouteActiveState.value) {
    // Watch when active - keeps provider alive and subscription active
    currentValue = watcher();
    // Update cache with latest value
    lastValueRef.value = currentValue;
  } else {
    // Route is inactive - use cached value (don't call watcher)
    currentValue = lastValueRef.value;
  }
  return currentValue as T;
}
