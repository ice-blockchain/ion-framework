// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_preferences_service.r.g.dart';

@Riverpod(keepAlive: true)
UserPreferencesService userPreferencesService(
  Ref ref, {
  required String identityKeyName,
}) {
  final localStorage = ref.watch(localStorageProvider);
  return UserPreferencesService(identityKeyName, localStorage);
}

@Riverpod(keepAlive: true)
UserPreferencesService? currentUserPreferencesService(Ref ref) {
  final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (identityKeyName == null) {
    return null;
  }
  return ref.watch(
    userPreferencesServiceProvider(identityKeyName: identityKeyName),
  );
}

class UserPreferencesService {
  UserPreferencesService(
    this._identityKeyName,
    this._localStorage,
  );

  final String _identityKeyName;
  final LocalStorage _localStorage;

  Future<void> setValue<T>(String key, T value) {
    final userKey = _getUserKey(key);
    if (T == bool) {
      return _localStorage.setBool(key: userKey, value: value as bool);
    } else if (T == int) {
      return _localStorage.setInt(userKey, value as int);
    } else if (T == double) {
      return _localStorage.setDouble(userKey, value as double);
    } else if (T == String) {
      return _localStorage.setString(userKey, value as String);
    } else if (T == List<String>) {
      return _localStorage.setStringList(userKey, value as List<String>);
    } else if (T == List<int>) {
      final stringList = (value as List<int>).map((e) => e.toString()).toList();
      return _localStorage.setStringList(userKey, stringList);
    } else {
      throw ArgumentError('Unsupported type: $T');
    }
  }

  T? getValue<T>(String key) {
    final userKey = _getUserKey(key);
    if (T == bool) {
      return _localStorage.getBool(userKey) as T?;
    } else if (T == int) {
      return _localStorage.getInt(userKey) as T?;
    } else if (T == double) {
      return _localStorage.getDouble(userKey) as T?;
    } else if (T == String) {
      return _localStorage.getString(userKey) as T?;
    } else if (T == List<String>) {
      return _localStorage.getStringList(userKey) as T?;
    } else if (T == List<int>) {
      final stringList = _localStorage.getStringList(userKey);
      if (stringList != null) {
        return stringList.map(int.parse).toList() as T?;
      }
      return null;
    } else {
      throw ArgumentError('Unsupported type: $T');
    }
  }

  void setEnum<T extends Enum>(String key, T value) {
    final userKey = _getUserKey(key);
    _localStorage.setEnum(userKey, value);
  }

  T? getEnum<T extends Enum>(String key, List<T> values) {
    final userKey = _getUserKey(key);
    return _localStorage.getEnum(userKey, values);
  }

  Future<void> remove(String key) {
    final userKey = _getUserKey(key);
    return _localStorage.remove(userKey);
  }

  Future<void> clear() async {
    final userKeyPrefix = _getUserKeyPrefix();
    await Future.wait(
      _localStorage.getKeys().map((key) {
        if (key.startsWith(userKeyPrefix)) {
          return _localStorage.remove(key);
        }
        return null;
      }).nonNulls,
    );
  }

  String _getUserKey(String key) => '${_getUserKeyPrefix()}:$key';

  String _getUserKeyPrefix() => 'user_$_identityKeyName';
}
