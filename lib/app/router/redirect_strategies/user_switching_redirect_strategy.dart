// SPDX-License-Identifier: ice License 1.0

// lib/app/router/redirect_strategies/user_switching_redirect_strategy.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallets_initializer_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/redirect_strategies/redirect_strategy.dart';

class UserSwitchingRedirectStrategy implements RedirectStrategy {
  @override
  Future<String?> getRedirect({
    required String location,
    required Ref ref,
  }) async {
    final isUserSwitching = ref.read(userSwitchingProvider);

    if (!isUserSwitching) {
      return null;
    }

    final isAuthenticated = (ref.read(authProvider).valueOrNull?.isAuthenticated).falseOrValue;

    final switchUserLoaderPath = SwitchUserLoaderRoute().location;
    final isOnSwitchUserLoader = location.contains(switchUserLoaderPath);

    if (!isOnSwitchUserLoader) {
      return switchUserLoaderPath;
    }

    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    final mainWallet = ref.read(mainWalletProvider);
    final walletsInitializer = ref.read(walletsInitializerNotifierProvider);

    final hasError = mainWallet.hasError || walletsInitializer.hasError;
    if (hasError) {
      ref.read(userSwitchingProvider.notifier).reset();
      return null;
    }

    final isReady = isAuthenticated && currentPubkey != null;

    if (isReady) {
      ref.read(userSwitchingProvider.notifier).reset();
    }

    return null;
  }
}
