// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion/app/features/wallets/data/database/tables/duration_type.dart';

@DataClassName('Coin')
class CoinsTable extends Table {
  TextColumn get id => text()();
  @JsonKey('contractAddress')
  TextColumn get contractAddress => text()();
  IntColumn get decimals => integer()();
  @JsonKey('iconURL')
  TextColumn get iconURL => text()();
  TextColumn get name => text()();
  @JsonKey('network')
  TextColumn get networkId => text()();
  @JsonKey('priceUSD')
  RealColumn get priceUSD => real()();
  TextColumn get symbol => text()();
  @JsonKey('symbolGroup')
  TextColumn get symbolGroup => text()();
  @JsonKey('syncFrequency')
  Column<Duration> get syncFrequency => customType(const DurationType())();
  BoolColumn get native => boolean()();
  BoolColumn get prioritized => boolean()();
  TextColumn get tokenizedCommunityExternalAddress => text().nullable()();
  TextColumn get tokenizedCommunityTokenType => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
