// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:ion/app/extensions/bool.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/feed/nft/sync/nft_collection_sync_controller.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_collection_sync_provider.r.g.dart';

/// Riverpod provider that manages the lifecycle of NFT collection sync.
@Riverpod(keepAlive: true)
class NftCollectionSync extends _$NftCollectionSync {
  @override
  Future<void> build() async {
    keepAliveWhenAuthenticated(ref);

    final isOnboardingComplete = await ref.watch(onboardingCompleteProvider.future);
    if (!isOnboardingComplete.falseOrValue) {
      return;
    }

    final hasCollection = await ref.watch(ionContentNftCollectionStateProvider.future);
    if (hasCollection) {
      return;
    }

    final controller = ref.watch(nftCollectionSyncControllerProvider)..startSync();

    ref.listen(appLifecycleProvider, (_, appLifecycleState) {
      if (appLifecycleState == AppLifecycleState.resumed) {
        controller.startSync();
      } else {
        controller.stopSync();
      }
    });
  }
}
