// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/wallets/data/database/dao/nfts_dao.m.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nfts_repository.r.g.dart';

@riverpod
NftsRepository nftsRepository(Ref ref) => NftsRepository(
      ref.watch(dioProvider),
      ref.watch(nftsDaoProvider),
    );

class NftsRepository {
  NftsRepository(
    this._dio,
    this._nftsDao,
  );

  final Dio _dio;
  final NftsDao _nftsDao;

  Future<void> upsertBaseNfts(List<NftData> nfts, {required String walletId}) {
    return _nftsDao.upsertBaseNfts(nfts, walletId: walletId);
  }

  Future<NftData?> getNftByIdentifier(NftIdentifier identifier) {
    return _nftsDao.getByIdentifier(identifier);
  }

  Future<NftData> getNftExtras(NftData nft, {required String walletId}) async {
    try {
      final cachedJson = await _nftsDao.getMetadataJson(nft: nft);
      if (cachedJson != null) {
        return _merge(nft, json.decode(cachedJson) as Map<String, dynamic>);
      }

      final response =
          await _dio.get<Map<String, dynamic>>(nft.tokenUri).timeout(const Duration(seconds: 12));
      final data = response.data;
      if (response.statusCode != 200 || data == null) {
        return nft; // fail soft, return base NFT
      }

      await _nftsDao.upsertMetadataJson(nft: nft, metadata: data);

      return _merge(nft, data);
    } on DioException {
      return nft; // network error → base NFT
    } on FormatException {
      return nft; // bad json → base NFT
    } on Exception {
      return nft; // any other error → base NFT
    }
  }

  NftData _merge(NftData base, Map<String, dynamic> meta) {
    final description = (meta['description'] as String?) ?? base.description;
    final image = (meta['image'] as String?) ?? base.collectionImageUri;
    final name = (meta['name'] as String?) ?? base.name;

    return base.copyWith(
      description: description,
      collectionImageUri: _normalizeImage(image),
      name: name,
    );
  }

  String _normalizeImage(String image) => image.replaceFirst('ipfs://', 'https://ipfs.io/ipfs/');
}
