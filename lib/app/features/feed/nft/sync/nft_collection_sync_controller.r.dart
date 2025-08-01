// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/nft/model/nft_collection_response.f.dart';
import 'package:ion/app/features/feed/nft/services/nft_collection_sync_service.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_collection_sync_controller.r.g.dart';

enum _SyncStatus { idle, running, syncing, completed }

/// Controls the background NFT collection sync process.
/// Manages timer, calls the service, and exposes start/stop/dispose methods.
class NftCollectionSyncController {
  NftCollectionSyncController({
    required this.service,
    required this.userMasterKey,
    required this.onSuccess,
    this.syncInterval = const Duration(seconds: 15),
  });

  final NftCollectionSyncService service;
  final String userMasterKey;
  final Duration syncInterval;
  final ValueChanged<TargetNftCollectionData> onSuccess;

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
      final result = await service.fetchAndFindTargetCollection(
        userMasterKey: userMasterKey,
        cancelToken: _cancelToken,
      );
      if (result != null) {
        _status = _SyncStatus.completed;
        onSuccess(result);
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
  final service = ref.watch(nftCollectionSyncServiceProvider);
  final notifier = ref.watch(ionContentNftCollectionStateProvider.notifier);

  if (userMasterKey == null) {
    throw Exception('User master key is required for NFT collection sync');
  }

  final controller = NftCollectionSyncController(
    service: service,
    userMasterKey: userMasterKey,
    onSuccess: notifier.setIonContentNftCollection,
  );

  ref.onDispose(controller.dispose);

  return controller;
}

@Riverpod(keepAlive: true)
class IonContentNftCollectionState extends _$IonContentNftCollectionState {
  @override
  Future<bool> build() async {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      throw const CurrentUserNotFoundException();
    }

    final userMetadata = await ref.watch(userMetadataProvider(currentPubkey, cache: false).future);
    final nftCollections = userMetadata?.data.ionContentNftCollections;
    if (nftCollections == null) {
      return false;
    }

    // TODO: check if nftCollections has a proper collection
    return false;
  }

  Future<void> setIonContentNftCollection(TargetNftCollectionData data) async {
    final currentUserMetadata = await ref.read(currentUserMetadataProvider.future);
    if (currentUserMetadata == null) {
      throw Exception('Current user metadata not found');
    }

    final newCollection = IonContentNftCollection(
      createdBy: data.creatorAddress,
      address: data.collectionAddress,
    );

    final updatedMetadata = currentUserMetadata.data.copyWith(
      ionContentNftCollections: {
        ...currentUserMetadata.data.ionContentNftCollections ?? {},
        data.name: newCollection,
      },
    );

    await ref.read(updateUserMetadataNotifierProvider.notifier).publish(updatedMetadata);
  }
}
