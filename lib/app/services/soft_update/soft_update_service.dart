// lib/app/services/soft_update/soft_update_service.dart
import 'dart:async';
import 'package:in_app_update/in_app_update.dart';
import 'package:ion/app/services/logger/logger.dart';

class SoftUpdateService {
  static const _tag = 'SoftUpdateService';
  Stream<InstallStatus> get installStatusStream => InAppUpdate.installUpdateListener;
  AppUpdateInfo? _currentUpdateInfo;

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      _currentUpdateInfo = updateInfo;

      return updateInfo;
    } catch (e) {
      Logger.error('$_tag: Failed to check for update: $e');
      return null;
    }
  }

  Future<bool> isUpdateAvailable() async {
    final updateInfo = await checkForUpdate();
    return updateInfo?.updateAvailability == UpdateAvailability.updateAvailable;
  }

  Future<AppUpdateResult> startFlexibleUpdate() async {
    try {
      if (_currentUpdateInfo?.updateAvailability != UpdateAvailability.updateAvailable) {
        throw Exception('No update available');
      }

      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        await _completeFlexibleUpdate();
      }

      return result;
    } catch (e) {
      Logger.error('$_tag Failed to start flexible update: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  Future<AppUpdateResult> _completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();

      return AppUpdateResult.success;
    } catch (e) {
      Logger.error('$_tag: Failed to complete flexible update: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  Future<AppUpdateResult> performImmediateUpdate() async {
    try {
      if (_currentUpdateInfo?.updateAvailability != UpdateAvailability.updateAvailable) {
        throw Exception('No update available');
      }

      final result = await InAppUpdate.performImmediateUpdate();
      return result;
    } catch (e) {
      Logger.error('$_tag: Failed to perform immediate update: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }
}
