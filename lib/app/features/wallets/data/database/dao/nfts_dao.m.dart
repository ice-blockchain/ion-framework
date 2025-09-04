// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/tables/networks_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/nfts_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nfts_dao.m.g.dart';

@Riverpod(keepAlive: true)
NftsDao nftsDao(Ref ref) => NftsDao(db: ref.watch(walletsDatabaseProvider));

@DriftAccessor(tables: [NftsTable, NetworksTable])
class NftsDao extends DatabaseAccessor<WalletsDatabase> with _$NftsDaoMixin {
  NftsDao({required WalletsDatabase db}) : super(db);

  Future<void> replaceWalletNfts(List<NftData> nfts, {required String walletId}) async {
    await transaction(() async {
      await (delete(nftsTable)..where((t) => t.walletId.equals(walletId))).go();
      await upsertBaseNfts(nfts, walletId: walletId);
    });
  }

  Future<void> upsertBaseNfts(List<NftData> nfts, {required String walletId}) async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAllOnConflictUpdate(
        nftsTable,
        nfts.map((nft) {
          return Nft(
            collectionImageUri: nft.collectionImageUri,
            contract: nft.contract,
            description: nft.description,
            kind: nft.kind,
            name: nft.name,
            networkId: nft.network.id,
            symbol: nft.symbol,
            tokenId: nft.tokenId,
            tokenUri: nft.tokenUri,
            walletId: walletId,
            metadataJson: '',
            createdAt: now,
            updatedAt: now,
          );
        }).toList(),
      );
    });
  }

  Future<NftData?> getByIdentifier(NftIdentifier identifier) async {
    final joined = await (select(nftsTable).join([
      innerJoin(networksTable, networksTable.id.equalsExp(nftsTable.networkId)),
    ])
          ..where(
            nftsTable.contract.equals(identifier.contract) &
                nftsTable.tokenId.equals(identifier.tokenId),
          ))
        .getSingleOrNull();

    if (joined == null) return null;

    final nftRow = joined.readTable(nftsTable);
    final networkRow = joined.readTable(networksTable);

    final networkData = NetworkData.fromDB(networkRow);

    return NftData(
      kind: nftRow.kind,
      contract: nftRow.contract,
      symbol: nftRow.symbol,
      tokenId: nftRow.tokenId,
      tokenUri: nftRow.tokenUri,
      description: nftRow.description,
      name: nftRow.name,
      collectionImageUri: nftRow.collectionImageUri,
      network: networkData,
    );
  }

  Future<String?> getMetadataJson({required NftData nft}) async {
    final q = selectOnly(nftsTable)
      ..addColumns([nftsTable.metadataJson])
      ..where(nftsTable.contract.equals(nft.contract))
      ..where(nftsTable.tokenId.equals(nft.tokenId))
      ..limit(1);

    final row = await q.getSingleOrNull();
    if (row == null) return null;

    final jsonString = row.read(nftsTable.metadataJson);
    if (jsonString == null || jsonString.isEmpty) return null;
    return jsonString;
  }

  Future<void> upsertMetadataJson({
    required NftData nft,
    required Map<String, dynamic> metadata,
  }) async {
    final now = DateTime.now();
    final jsonString = json.encode(metadata);

    final image = (metadata['image'] as String?) ?? '';
    final description = (metadata['description'] as String?) ?? '';
    final name = (metadata['name'] as String?) ?? nft.name;

    await (update(nftsTable)
          ..where((t) => t.contract.equals(nft.contract) & t.tokenId.equals(nft.tokenId)))
        .write(
      NftsTableCompanion(
        collectionImageUri: Value(image),
        description: Value(description),
        name: Value(name),
        metadataJson: Value(jsonString),
        updatedAt: Value(now),
      ),
    );
  }
}
