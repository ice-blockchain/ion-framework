// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';

@DataClassName('Nft')
class NftsTable extends Table {
  @override
  String get tableName => 'nfts_table';

  TextColumn get collectionImageUri => text()();
  TextColumn get contract => text()();
  TextColumn get description => text()();
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get networkId => text()();
  TextColumn get symbol => text()();
  TextColumn get tokenId => text()();
  TextColumn get tokenUri => text()();
  TextColumn get walletId => text()();

  // Raw JSON metadata payload
  TextColumn get metadataJson => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {contract, tokenId, walletId};
}
