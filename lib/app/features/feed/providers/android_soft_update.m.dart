import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:ion/app/constants/links.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/soft_update/soft_update_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'android_soft_update.m.freezed.dart';
part 'android_soft_update.m.g.dart';

enum AndroidUpdateState { initial, loading, success, error }

@freezed
class AndroidSoftUpdateState with _$AndroidSoftUpdateState {
  const factory AndroidSoftUpdateState({
    required bool isUpdateAvailable,
    required AndroidUpdateState updateState,
  }) = _AndroidSoftUpdateState;

  const AndroidSoftUpdateState._();
}

@Riverpod(keepAlive: true)
class AndroidSoftUpdate extends _$AndroidSoftUpdate {
  static const _tag = 'AndroidSoftUpdate';

  late final SoftUpdateService _softUpdateService = SoftUpdateService();
  AppUpdateInfo? _currentUpdateInfo;
  StreamSubscription<InstallStatus>? _subscription;

  @override
  AndroidSoftUpdateState build() {
    const initial = AndroidSoftUpdateState(
      isUpdateAvailable: false,
      updateState: AndroidUpdateState.initial,
    );

    _init();
    ref.onDispose(() => _subscription?.cancel());

    return initial;
  }

  Future<void> _init() async {
    ref.listen<AppLifecycleState>(
      appLifecycleProvider,
      (previous, next) async {
        if (next == AppLifecycleState.resumed) {
          if (state.isUpdateAvailable == false) {
            await _checkForUpdates();
          }
        }
      },
    );

    await _checkForUpdates();
    _listenInstallStatus();
  }

  Future<void> _checkForUpdates() async {
    try {
      if (!Platform.isAndroid) return;

      _currentUpdateInfo = await _softUpdateService.checkForUpdate();
      final isAvailable =
          _currentUpdateInfo?.updateAvailability == UpdateAvailability.updateAvailable;

      state = state.copyWith(isUpdateAvailable: isAvailable);
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: '$_tag: Failed to check for updates');
      state = state.copyWith(isUpdateAvailable: false);
    }
  }

  void _listenInstallStatus() {
    _subscription?.cancel();
    _subscription = _softUpdateService.installStatusStream.listen((status) {
      final mapped = _mapInstallStatus(status);
      state = state.copyWith(updateState: mapped);
    });
  }

  Future<void> tryToStartUpdate() async {
    final info = _currentUpdateInfo;
    if (!Platform.isAndroid) {
      Logger.warning('$_tag: Soft update is only available on Android');
      return;
    }

    if (info == null) {
      _openExternalStoreLink();
      return;
    }

    if (info.flexibleUpdateAllowed) {
      await startFlexibleUpdate();
    } else if (info.immediateUpdateAllowed) {
      await _startImmediateUpdate();
    } else {
      _openExternalStoreLink();
    }
  }

  Future<void> startFlexibleUpdate() async {
    try {
      state = state.copyWith(updateState: AndroidUpdateState.loading);

      final result = await _softUpdateService.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        state = state.copyWith(updateState: AndroidUpdateState.success);
      } else {
        _openExternalStoreLink();
        state = state.copyWith(updateState: AndroidUpdateState.error);
      }
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: '$_tag: Failed to start flexible update');
      state = state.copyWith(updateState: AndroidUpdateState.error);
    }
  }

  Future<void> _startImmediateUpdate() async {
    try {
      state = state.copyWith(updateState: AndroidUpdateState.loading);
      final result = await _softUpdateService.performImmediateUpdate();
      if (result == AppUpdateResult.success) {
        state = state.copyWith(updateState: AndroidUpdateState.success);
      } else {
        _openExternalStoreLink();
        state = state.copyWith(updateState: AndroidUpdateState.error);
      }
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: '$_tag: Failed to start immediate update');
      state = state.copyWith(updateState: AndroidUpdateState.error);
    }
  }

  void markModalAsShown() {
    state = state.copyWith(isUpdateAvailable: false);
  }

  void _openExternalStoreLink() {
    openUrl(Links.appUpdate);
  }

  AndroidUpdateState _mapInstallStatus(InstallStatus status) {
    switch (status) {
      case InstallStatus.downloading:
      case InstallStatus.pending:
      case InstallStatus.installing:
        return AndroidUpdateState.loading;
      case InstallStatus.installed:
        return AndroidUpdateState.success;
      case InstallStatus.failed:
      case InstallStatus.canceled:
        return AndroidUpdateState.error;
      case InstallStatus.unknown:
      case InstallStatus.downloaded:
        return AndroidUpdateState.initial;
    }
  }
}
