// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/boosted_post_info.f.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'boosted_posts_repository.r.g.dart';

class BoostedPostsRepository {
  BoostedPostsRepository({
    required LocalStorage localStorage,
  }) : _localStorage = localStorage;

  final LocalStorage _localStorage;

  static const _storageKeyPrefix = 'boosted_posts_';
  static const _metaSuffix = '_meta';

  String _idsKey(String masterPubkey) => '$_storageKeyPrefix$masterPubkey';
  String _metaKey(String masterPubkey) => '$_storageKeyPrefix$masterPubkey$_metaSuffix';

  Future<Set<String>> loadBoostedIds(String masterPubkey) async {
    final stored = _localStorage.getStringList(_idsKey(masterPubkey)) ?? const <String>[];
    return stored.toSet();
  }

  Future<Map<String, BoostPostData>> loadBoostedMeta(String masterPubkey) async {
    final rawMeta = _localStorage.getString(_metaKey(masterPubkey));
    if (rawMeta == null) {
      return <String, BoostPostData>{};
    }

    final decoded = jsonDecode(rawMeta);
    if (decoded is! Map<String, dynamic>) {
      return <String, BoostPostData>{};
    }

    final result = <String, BoostPostData>{};
    decoded.forEach((id, value) {
      if (value is Map<String, dynamic>) {
        result[id] = BoostPostData.fromJson(value);
      }
    });

    return result;
  }

  Future<void> saveBoosted(
    String masterPubkey, {
    required Set<String> ids,
    required Map<String, BoostPostData> meta,
  }) async {
    await _localStorage.setStringList(_idsKey(masterPubkey), ids.toList());

    final toStore = meta.map((id, info) => MapEntry(id, info.toJson()));
    await _localStorage.setString(_metaKey(masterPubkey), jsonEncode(toStore));
  }
}

@Riverpod(keepAlive: true)
BoostedPostsRepository boostedPostsRepository(Ref ref) {
  final storage = ref.watch(localStorageProvider);
  return BoostedPostsRepository(localStorage: storage);
}
