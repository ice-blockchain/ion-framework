// SPDX-License-Identifier: ice License 1.0

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_provider.r.dart';
import 'package:ion/app/features/auth/providers/relays_assigned_provider.r.dart';
import 'package:ion/app/features/auth/views/pages/link_new_device/link_new_device_dialog.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/core/providers/init_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/core/views/pages/error_page.dart';
import 'package:ion/app/features/feed/providers/android_soft_update.m.dart';
import 'package:ion/app/features/force_update/providers/force_update_provider.r.dart';
import 'package:ion/app/features/force_update/view/pages/app_update_modal.dart';
import 'package:ion/app/features/push_notifications/providers/initial_notification_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/notification_response_service.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_route_observer.dart';
import 'package:ion/app/router/app_router_listenable.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/redirect_strategies/user_switching_redirect_strategy.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'go_router_provider.r.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    refreshListenable: AppRouterNotifier(ref),
    redirect: (context, state) async {
      final initState = ref.read(initAppProvider);
      final isSplashAnimationCompleted = ref.read(splashProvider);
      final forceUpdateRequired = ref.read(forceUpdateProvider).valueOrNull.falseOrValue;
      final androidUpdateState = ref.read(androidSoftUpdateProvider);
      final isAndroidSoftUpdateRequired =
          androidUpdateState.isUpdateAvailable && !androidUpdateState.modalWasShown;
      final isOnSplash = state.matchedLocation.startsWith(SplashRoute().location);
      final isInitInProgress = initState.isLoading;
      final isInitError = initState.hasError;

      if (!forceUpdateRequired && !isOnSplash && isAndroidSoftUpdateRequired) {
        ref.read(uiEventQueueNotifierProvider.notifier).emit(const ShowInAppUpdateModalEvent());
      }

      if (forceUpdateRequired && !isOnSplash) {
        ref.read(uiEventQueueNotifierProvider.notifier).emit(const ShowAppUpdateModalEvent());
      }

      if (isInitError && !isInitInProgress) {
        Logger.log(
          'Init error',
          error: initState.error.toString(),
          stackTrace: initState.stackTrace,
        );

        print('Router init error: ${initState.error}');
        return ErrorRoute(message: initState.error.toString()).location;
      }

      if (isInitInProgress || !isSplashAnimationCompleted) {
        // Redirect if app is not initialized yet, but avoid re-entering Splash when already there
        return SplashRoute().location;
      }

      final initialNotification = ref.read(initialNotificationProvider.notifier).consume();
      if (initialNotification != null) {
        await ref
            .read(notificationResponseServiceProvider)
            .handleNotificationResponse(initialNotification, isInitialNotification: true);
        return null;
      }

      final result = await _mainRedirect(location: state.matchedLocation, ref: ref);
      return result;
    },
    routes: $appRoutes,
    errorBuilder: (context, state) {
      print('Router error: ${state.error}');
      return ErrorPage(message: state.error?.toString());
    },
    initialLocation: SplashRoute().location,
    debugLogDiagnostics: ref.read(featureFlagsProvider.notifier).get(LoggerFeatureFlag.logRouters),
    navigatorKey: rootNavigatorKey,
    observers: [routeObserver],
  );
}

Future<String?> _mainRedirect({
  required String location,
  required Ref ref,
}) async {
  final userSwitchingStrategy = UserSwitchingRedirectStrategy();
  final userSwitchingRedirect = await userSwitchingStrategy.getRedirect(
    location: location,
    ref: ref,
  );
  if (userSwitchingRedirect != null) {
    if (location != userSwitchingRedirect) {
      print('Router user switching redirect: $userSwitchingRedirect');
      return userSwitchingRedirect;
    } else {
      return null;
    }
  }

  final isAuthenticated = (ref.read(authProvider).valueOrNull?.isAuthenticated).falseOrValue;

  final onboardingComplete = isAuthenticated
      ? await ref.read(onboardingCompleteProvider.future)
      : ref.read(onboardingCompleteProvider).valueOrNull;

  final hasNotificationsPermission = ref.read(hasPermissionProvider(Permission.notifications));

  final isOnSplash = location.startsWith(SplashRoute().location);
  final isOnAuth = location.contains('/${AuthRoutes.authPrefix}/');
  final isOnOnboarding = location.contains('/${AuthRoutes.onboardingPrefix}/');
  final isOnMediaPicker = location.contains(MediaPickerRoutes.routesPrefix);
  final isOnFeed = location == FeedRoute().location;
  final isOnIntro = location == IntroRoute().location;

  if (!isAuthenticated && !isOnAuth) {
    final introLocation = IntroRoute().location;
    if (location != introLocation) {
      print('Router intro redirect: $introLocation');
      return introLocation;
    }

    return null;
  }

  if (isAuthenticated && onboardingComplete != null) {
    if (onboardingComplete) {
      if (isOnSplash || isOnAuth || isOnIntro) {
        final feedLocation = FeedRoute().location;
        if (location != feedLocation) {
          print('Router feed redirect: $feedLocation');
          return feedLocation;
        }

        return null;
      } else if (isOnOnboarding) {
        if (hasNotificationsPermission) {
          final feedLocation = FeedRoute().location;
          if (location != feedLocation) {
            print('Router feed redirect: $feedLocation');
            return feedLocation;
          }

          return null;
        } else {
          final notificationsLocation = NotificationsRoute().location;
          if (location != notificationsLocation) {
            print('Router notifications redirect: $notificationsLocation');
            return notificationsLocation;
          }

          return null;
        }
      }
    }

    final hasUserMetadata = ref.read(currentUserMetadataProvider).valueOrNull != null;
    final delegationComplete = ref.read(delegationCompleteProvider).valueOrNull.falseOrValue;
    final relaysAssigned = ref.read(relaysAssignedProvider).valueOrNull.falseOrValue;

    if (!onboardingComplete &&
        !isOnOnboarding &&
        !isOnMediaPicker &&
        !(hasUserMetadata && relaysAssigned)) {
      final fillProfileLocation = FillProfileRoute().location;
      if (location != fillProfileLocation) {
        print('Router fill profile redirect: $fillProfileLocation');
        return fillProfileLocation;
      }

      return null;
    }

    if (!onboardingComplete &&
        !isOnFeed &&
        !isOnOnboarding &&
        hasUserMetadata &&
        relaysAssigned &&
        !delegationComplete) {
      ref.read(uiEventQueueNotifierProvider.notifier).emit(const ShowLinkNewDeviceDialogEvent());
      final feedLocation = FeedRoute().location;
      if (location != feedLocation) {
        print('Router feed redirect: $feedLocation');
        return feedLocation;
      }

      return null;
    }
  }

  return null;
}
