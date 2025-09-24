// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/selected_wallet_view_id_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class Listener<T> extends Mock {
  void call(T? previous, T value);
}

class MockLocalStorage extends Mock implements LocalStorage {}

class MockSelectedWalletIdNotifier extends Notifier<String?>
    with Mock
    implements SelectedWalletViewIdNotifier {}

class MockWalletsDataNotifier extends AsyncNotifier<List<WalletViewData>>
    with Mock
    implements WalletViewsDataNotifier {
  MockWalletsDataNotifier(this._data);

  final List<WalletViewData> _data;

  @override
  Future<List<WalletViewData>> build() async {
    return _data;
  }
}

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerPlatform() : super();

  @override
  Future<void> init() async {}

  @override
  Future<int> create(DataSource dataSource) async => 1;

  @override
  Future<void> dispose(int textureId) async {}

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int textureId) => const SizedBox();
}

class FakeVideoController extends ValueNotifier<VideoPlayerValue> implements VideoPlayerController {
  FakeVideoController(Duration duration) : super(const VideoPlayerValue.uninitialized()) {
    value = value.copyWith(
      isInitialized: true,
      duration: duration,
      position: Duration.zero,
      volume: 0,
      size: const Size(1280, 720),
    );
  }

  @override
  int get playerId => 1;

  @override
  DataSourceType get dataSourceType => DataSourceType.asset;

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekTo(Duration p) async => value = value.copyWith(position: p);

  @override
  Future<void> dispose() async => super.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVideoFactory extends VideoPlayerControllerFactory {
  FakeVideoFactory(this._controller) : super(sourcePath: 'dummy');
  final VideoPlayerController _controller;

  @override
  Future<VideoPlayerController> createController({
    required Completer<void> cancelToken,
    VideoPlayerOptions? options,
    bool? forceNetworkDataSource,
  }) async {
    return SynchronousFuture<VideoPlayerController>(_controller);
  }
}

class MockEnv extends Notifier<void> with Mock implements Env {}
