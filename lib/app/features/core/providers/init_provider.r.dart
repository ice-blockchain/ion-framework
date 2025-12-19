// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_provider.r.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/core/providers/template_provider.r.dart';
import 'package:ion/app/features/core/providers/window_manager_provider.r.dart';
import 'package:ion/app/features/core/views/components/widget_error_builder.dart';
import 'package:ion/app/features/feed/nft/providers/nft_collection_sync_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/feed/providers/feed_feature_initializer.dart';
import 'package:ion/app/features/force_update/providers/force_update_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/global_subscription.r.dart';
import 'package:ion/app/features/push_notifications/background/firebase_messaging_background_service.dart';
import 'package:ion/app/features/push_notifications/providers/pushes_init_provider.r.dart';
import 'package:ion/app/features/user/providers/account_notifications_sync_provider.r.dart';
import 'package:ion/app/features/user/providers/force_account_security_notifier.r.dart';
import 'package:ion/app/features/user/providers/relays/user_chat_relays_sync_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/user_file_storage_relays_sync_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_sync_provider.r.dart';
import 'package:ion/app/features/user/providers/user_awards_sync_provider.r.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_service.r.dart';
import 'package:ion/app/features/wallets/providers/coins_sync_provider.r.dart';
import 'package:ion/app/features/wallets/providers/user_public_wallets_sync_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallets_initializer_provider.r.dart';
import 'package:ion/app/services/conversion_tracking/facebook_conversion_tracking_service.r.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/http_client/http_client.dart';
import 'package:ion/app/services/ion_connect/ion_connect.dart';
import 'package:ion/app/services/ion_connect/ion_connect_logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/utils/functions.dart';
import 'package:ion/l10n/timeago_locales.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'init_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<void> initApp(Ref ref) async {
  final featureFlagsNotifier = ref.read(featureFlagsProvider.notifier);
  final logIonConnect = featureFlagsNotifier.get(LoggerFeatureFlag.logIonConnect);

  setGlobalHttpOverrides();

  ErrorWidget.builder = WidgetErrorBuilder.new;

  IonConnect.initialize(logIonConnect ? IonConnectLogger() : null);

  await FeedFeatureInitializer().init(ref);

  await Future.wait([
    ref.read(windowManagerProvider.notifier).show(),
    ref.read(sharedPreferencesProvider.future),
    ref.read(appTemplateProvider.future),
    ref.read(authProvider.future),
    ref.read(permissionsProvider.notifier).checkAllPermissions(),
    ref.read(onboardingCompleteProvider.future),
    ref.read(forceUpdateProvider.future),
    ref.read(deeplinkInitializerProvider.future),
    ref.read(facebookConversionTrackingServiceProvider.future),
  ]);

  // `ref.read` lets `coinsSyncProvider` be disposed even though it's a keepAlive provider
  // so we need to listen to it to keep it alive. The same with transactionsSubscription.
  ref
    ..listen(coinsSyncProvider, noop)
    ..listen(nftCollectionSyncProvider, noop)
    ..listen(walletsInitializerNotifierProvider, noop)
    ..listen(userPublicWalletsSyncProvider, noop)
    ..listen(userRelaysSyncProvider, noop)
    ..listen(userAwardsSyncProvider, noop)
    ..listen(forceAccountSecurityServiceProvider, noop)
    ..listen(bscWalletCheckServiceProvider, noop)
    ..listen(userChatRelaysSyncProvider, noop)
    ..listen(userFileStorageRelaysSyncProvider, noop)
    ..listen(feedBookmarksSyncProvider, noop)
    ..listen(feedBookmarkCollectionsNotifierProvider, noop)
    ..listen(pushesInitProvider, noop)
    ..listen(globalSubscriptionProvider, (_, subscription) => subscription?.init())
    ..listen(accountNotificationsSyncProvider, noop)
    ..listen(deepLinkHandlerProvider, noop);

  initFirebaseMessagingBackgroundHandler();

  registerTimeagoLocalesForEnum();
}
