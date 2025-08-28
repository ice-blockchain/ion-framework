// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'secure_storage.r.g.dart';

class SecureStorage {
  // Use accessibility settings that allow access when device is locked
  // This is required for iOS notification service extensions
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<String?> getString({required String key}) async {
    final value = await _storage.read(key: key);
    if (value != null) return value;

    // Backwards compatibility with old secure storage options
    final oldStorageValue = await _storage.read(
      key: key,
      iOptions: IOSOptions.defaultOptions,
      aOptions: AndroidOptions.defaultOptions,
    );
    if (oldStorageValue != null) {
      unawaited(setString(key: key, value: oldStorageValue));
    }
    return oldStorageValue;
  }

  Future<void> setString({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  Future<void> remove({required String key}) {
    return Future.wait([
      _storage.delete(key: key),
      // Backwards compatibility with old secure storage options
      _storage.delete(
        key: key,
        iOptions: IOSOptions.defaultOptions,
        aOptions: AndroidOptions.defaultOptions,
      ),
    ]);
  }

  /// Forcefully clear secure storage after app installation or reinstallation.
  /// This is necessary because the iOS keychain retains values even after the app is deleted.
  Future<void> clearOnReinstall() async {
    const key = 'SecureStorage:hasRunBefore';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(key) == null) {
      await Future.wait([
        _storage.deleteAll(),
        // Backwards compatibility with old secure storage options
        _storage.deleteAll(
          iOptions: IOSOptions.defaultOptions,
          aOptions: AndroidOptions.defaultOptions,
        ),
        prefs.setBool(key, true),
      ]);
    }
  }
}

@Riverpod(keepAlive: true)
SecureStorage secureStorage(Ref ref) {
  return SecureStorage();
}
