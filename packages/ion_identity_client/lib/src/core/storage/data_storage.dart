// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rxdart/rxdart.dart';

/// A generic data storage class that stores a `Map<String, T>` in `FlutterSecureStorage`
/// and allows for CRUD operations on that map. It also exposes a stream of changes,
/// allowing clients to react to data updates over time.
class DataStorage<T> {
  DataStorage({
    required FlutterSecureStorage secureStorage,
    required String storageKey,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  })  : _secureStorage = secureStorage,
        _storageKey = storageKey,
        _fromJson = fromJson,
        _toJson = toJson {
    // Initialize the subject with an empty map. Once init() is called, it will load actual data.
    _dataSubject = BehaviorSubject.seeded(const {});
  }

  final FlutterSecureStorage _secureStorage;
  final String _storageKey;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;

  /// In-memory cache of items mapped by their keys.
  final Map<String, T> _cache = {};

  late final BehaviorSubject<Map<String, T>> _dataSubject;

  /// A stream of the current data as a `Map<String, T>`.
  /// Every time data changes (add/update/remove/clear), a new map is emitted.
  Stream<Map<String, T>> get dataStream => _dataSubject.stream;

  /// Initializes the storage by loading existing data from secure storage.
  /// If no data exists, the cache starts empty.
  /// After loading, emits the current data state.
  Future<void> init() async {
    await _loadFromStorage();
    _emitCurrentData();
  }

  /// Retrieves the data associated with the specified [key].
  /// Returns `null` if no data is found.
  T? getData({required String key}) {
    return _cache[key];
  }

  /// Sets (adds or updates) the data for a given [key].
  /// After saving, emits the updated data map.
  Future<void> setData({required String key, required T value}) async {
    _cache[key] = value;
    await _saveToStorage();
    _emitCurrentData();
  }

  /// Removes the data associated with the specified [key].
  /// After removal, emits the updated data map.
  Future<void> removeData({required String key}) async {
    _cache.remove(key);
    await _saveToStorage();
    _emitCurrentData();
  }

  /// Clears all stored data.
  /// After clearing, emits the updated (empty) data map.
  Future<void> clearAllData() async {
    _cache.clear();
    await _saveToStorage();
    _emitCurrentData();
  }

  /// Returns all data as a Map.
  Map<String, T> getAllData() {
    return Map.unmodifiable(_cache);
  }

  /// Returns all data keys.
  List<String> getAllKeys() {
    return _cache.keys.toList(growable: false);
  }

  /// Closes the stream when done.
  void dispose() {
    _dataSubject.close();
  }

  Future<void> _loadFromStorage() async {
    final jsonStr = await _secureStorage.read(key: _storageKey);
    if (jsonStr == null) {
      return; // No data to load, keep cache empty.
    }

    final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
    _cache
      ..clear()
      ..addAll(
        jsonMap.map((key, value) {
          // value should be a Map<String, dynamic> representing T
          return MapEntry(key, _fromJson(value as Map<String, dynamic>));
        }),
      );
  }

  /// Saves the current cache to secure storage.
  Future<void> _saveToStorage() async {
    final jsonMap = _cache.map((key, value) => MapEntry(key, _toJson(value)));
    final jsonStr = json.encode(jsonMap);
    await _secureStorage.write(key: _storageKey, value: jsonStr);
  }

  void _emitCurrentData() {
    // Emit an unmodifiable view of the current cache state.
    _dataSubject.add(Map.unmodifiable(_cache));
  }
}
