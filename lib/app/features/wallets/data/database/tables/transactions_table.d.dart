// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';

@DataClassName('Transaction')
class TransactionsTable extends Table {
  static const defaultWalletViewIdForDeprecated = '';
  // Transaction required fields
  TextColumn get type => text()(); // In, Out
  TextColumn get txHash => text()();
  TextColumn get networkId => text()();
  // Can be the same, as native one. Null if asset is nft.
  TextColumn get coinId => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get senderWalletAddress => text().nullable()();
  TextColumn get receiverWalletAddress => text().nullable()();
  TextColumn get walletViewId => text()();
  TextColumn get externalHash => text().nullable()();

  // Fields, that will be available from ion service
  TextColumn get id => text().nullable()();
  TextColumn get fee => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get nativeCoinId => text().nullable()(); // to get decimals to calculate fee
  DateTimeColumn get dateConfirmed => dateTime().nullable().map(const UtcDateTimeConverter())();
  DateTimeColumn get dateRequested => dateTime().nullable().map(const UtcDateTimeConverter())();

  // Entity fields
  DateTimeColumn get createdAtInRelay => dateTime().nullable().map(const UtcDateTimeConverter())();
  // sender, if current user receiver, and vice versa
  TextColumn get userPubkey => text().nullable()();
  // If asset is nft
  TextColumn get assetId => text().nullable()();
  // NFT identifier (contract_tokenId format)
  TextColumn get nftIdentifier => text().nullable()();
  // Asset contract address for tokens/NFTs
  TextColumn get assetContractAddress => text().nullable()();
  // If asset is coin
  TextColumn get transferredAmount => text().nullable()();
  RealColumn get transferredAmountUsd => real().nullable()();

  // For 1756 event id
  TextColumn get eventId => text().nullable()();

  @override
  String? get tableName => 'transactions_table_v2';

  @override
  Set<Column> get primaryKey => {txHash, walletViewId, type};
}

/// We need to be sure that the data in the db is stored in a single format,
/// so a custom type converter was used for that purpose.
class UtcDateTimeConverter extends TypeConverter<DateTime?, DateTime?> {
  const UtcDateTimeConverter();

  @override
  DateTime? fromSql(DateTime? fromDb) => fromDb?.toUtc();

  @override
  DateTime? toSql(dynamic value) => value is DateTime ? value.toUtc() : null;
}
