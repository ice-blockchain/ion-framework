// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/nft/providers/ion_content_nft_collection_notifier.r.dart';
import 'package:ion/app/features/feed/nft/services/nft_collection_sync_service.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_collection_sync_controller.r.g.dart';

const ionContentNftCollectionName = 'ion-content-nft-collection';

enum _SyncStatus { idle, running, syncing, completed }

/// Controls the background NFT collection sync process.
/// Manages timer, calls the service, and exposes start/stop/dispose methods.
class NftCollectionSyncController {
  NftCollectionSyncController({
    required this.ionContentNftCollectionNotifier,
    required this.service,
    required this.userMasterKey,
    this.syncInterval = const Duration(seconds: 15),
  });

  final IonContentNftCollectionNotifier ionContentNftCollectionNotifier;
  final NftCollectionSyncService service;
  final String userMasterKey;
  final Duration syncInterval;

  Timer? _timer;
  CancelToken? _cancelToken;
  _SyncStatus _status = _SyncStatus.idle;

  void startSync() {
    if (_status == _SyncStatus.running || _status == _SyncStatus.completed) return;
    _status = _SyncStatus.running;
    _performSync();
    _timer?.cancel();
    _timer = Timer.periodic(syncInterval, (_) => _performSync());
  }

  void stopSync() {
    _timer?.cancel();
    _timer = null;
    _cancelToken?.cancel();
    _cancelToken = null;
    _status = _SyncStatus.idle;
  }

  void dispose() {
    stopSync();
  }

  Future<void> _performSync() async {
    if (_status == _SyncStatus.completed) {
      stopSync();
      return;
    }
    if (_status == _SyncStatus.syncing) return;
    _status = _SyncStatus.syncing;
    _cancelToken = CancelToken();
    try {
      final nftCollection = await service.getNftCollectionData(
        userMasterKey: userMasterKey,
        cancelToken: _cancelToken,
      );
      if (nftCollection != null) {
        _status = _SyncStatus.completed;
        await ionContentNftCollectionNotifier.updateUserMetadata(nftCollection);
        stopSync();
      }
    } catch (e, st) {
      if (e is DioException && CancelToken.isCancel(e)) {
        Logger.log('Sync cancelled');
      } else {
        Logger.log('Failed to sync NFT collection: $e', error: e, stackTrace: st);
      }
    } finally {
      _cancelToken = null;
      if (_status != _SyncStatus.completed) {
        _status = _SyncStatus.running;
      }
    }
  }
}

@Riverpod(keepAlive: true)
NftCollectionSyncController nftCollectionSyncController(Ref ref) {
  final userMasterKey = ref.watch(currentPubkeySelectorProvider);
  if (userMasterKey == null) {
    throw const CurrentUserNotFoundException();
  }

  final service = ref.watch(nftCollectionSyncServiceProvider);
  final ionContentNftCollectionNotifier =
      ref.watch(ionContentNftCollectionNotifierProvider.notifier);

  final controller = NftCollectionSyncController(
    service: service,
    userMasterKey: userMasterKey,
    ionContentNftCollectionNotifier: ionContentNftCollectionNotifier,
  );

  ref.onDispose(controller.dispose);

  return controller;
}

@Riverpod(keepAlive: true)
Future<bool> hasIonContentNftCollection(Ref ref) async {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentPubkey == null) {
    throw const CurrentUserNotFoundException();
  }

  final userMetadata = await ref.watch(userMetadataProvider(currentPubkey, cache: false).future);
  final nftCollections = userMetadata?.data.ionContentNftCollections;
  if (nftCollections == null) {
    return false;
  }

  return nftCollections.containsKey(ionContentNftCollectionName);
}
